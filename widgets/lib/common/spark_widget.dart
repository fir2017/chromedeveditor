// Copyright (c) 2013, Google Inc. Please see the AUTHORS file for details.
// All rights reserved. Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

library spark_widgets;

import 'dart:async';
import 'dart:html';

import 'package:polymer/polymer.dart';

const bool IS_DART2JS = identical(1, 1.0);

/**
 * An annotation to be used on published properties instead of @published when:
 * * The property's matching attribute is used in the element's CSS,
 *   e.g. for conditional rules such as `:host([attr="something"]) {}`;
 * * The property will be set/changed via anything else but a direct attribute
 *   assignment on the client-side HTML without any use of data-binding:
 *     <x-element attr="something">
 *   "Anything else" include, but might not be limited to one of:
 *   - Direct assignment inside the element's own Dart:
 *       void foo() { attr = "something"; }
 *   - Direct assignment on the client-side Dart:
 *       XElement elt = querySelector(...); elt.attr = "something";
 *   - Data-binding inside another, outer element:
 *       <polymer-element name="outer-element" attributes="attr2">
 *         ...
 *           <x-element attr="{{attr2}}">
 */
const published_reflected = const PublishedProperty(reflect: true);

/**
 * A common base for all the widgets, internal and external.
 * Provides some common boilerplate and useful utility methods.
 * Not intended to be used directly.
 */
@CustomTag('spark-widget')
class SparkWidget extends PolymerElement {
  Element _focusableChild;

  SparkWidget.created() : super.created();

  @override
  void attached() {
    super.attached();

    _focusableChild = _findFocusableChild();
    if (_focusableChild != null) {
      enableKeyboardEvents(_focusableChild);
    }
  }

  Element getShadowDomElement(String selectors) =>
      shadowRoot.querySelector(selectors);

  void setAttr(String attr, bool add, [String value = '']) {
    if (add) {
      attributes[attr] = value;
    } else {
      attributes.remove(attr);
    }
  }

  Element _findFocusableChild() {
    ElementList elts = this.querySelectorAll('[focused]');
    if (elts.isEmpty) {
      elts = shadowRoot.querySelectorAll('[focused]');
    }

    if (elts.isEmpty) return null;

    // Theoretically, only one element in a widget is expected to have
    // `focused` attribute. However, this may not be true if a widget
    // instantiates other widgets and passes some focusable nodes to them
    // via <content>. So for now just print a warning and return first element.
    if (elts.length > 1) {
      print("WARNING: $runtimeType #$id has > 1 child with 'focused' attribute");
    }
    return elts.first;
  }

  /**
   * Override the standard behavior of the built-in focus():
   * look for a sub-element with an `focused` attribute, first in the
   * light DOM and then in shadow DOM, and if found, focus it; otherwise,
   * focus ourselves.
   *
   * Note that the found sub-element may itself be a
   * SparkWidget, and as such trigger a recursive autofocusing process.
   */
  @override
  void focus() {
    super.focus();
    _applyAutofocus(true);
  }

  /**
   * Override the standard behavior of the built-in blur():
   * reverse the effect of a previous call to [focus].
   */
  @override
  void blur() {
    super.blur();
    _applyAutofocus(false);
  }

  /**
   * Perform the actual autofocusing used in [focus] and [blur].
   */
  void _applyAutofocus(bool isFocused) {
    if (_focusableChild != null) {
      isFocused ? _focusableChild.focus() : _focusableChild.blur();
    }
  }

  /**
   * Put an opaque veil over the element.
   */
  void veil() {
    classes..remove('unveiled')..toggle('veiled', true);
  }

  /**
   * Undo the result of [veil].
   */
  void unveil() {
    classes..remove('veiled')..toggle('unveiled', true);
  }

  /**
   * Prevent FOUC (Flash Of Unstyled Content).
   */
  void preventFlashOfUnstyledContent({Function method,
                                      Duration delay}) {
    // TODO(ussuri): We use a temporary crude way here. Polymer's advertised
    // machanisms (via :resolved pseudo class as well as older .polymer-veiled
    // class) have failed to work so far, although :unresolved reportedly
    // functions in Chrome 34. Revisit.
    veil();

    if (method != null) {
      method();
    }

    if (delay != null) {
      asyncTimer(unveil, delay);
    } else {
      unveil();
    }
  }

  /**
   * Returns true if the point is within the widget's boundary.
   */
  bool isPointInWidget(Point xyGlobal) {
    /*%TRACE3*/ print("""(4> 7/9/14): super.getBoundingClientRect().containsPoint(xyGlobal): ${super.getBoundingClientRect().containsPoint(xyGlobal)}"""); // TRACE%
    /*%TRACE3*/ print("""(4> 7/9/14): super.getBoundingClientRect(): ${super.getBoundingClientRect()}"""); // TRACE%
    /*%TRACE3*/ print("""(4> 7/9/14): xyGlobal: ${xyGlobal}"""); // TRACE%
    return super.getBoundingClientRect().containsPoint(xyGlobal);
  }

  /**
   * Returns true if the event is within the widget's boundary or targets the
   * widget or one of its light DOM or shadow DOM children.
   */
  bool isEventInWidget(Event e) {
    /*%TRACE3*/ print("""(4> 7/9/14): e is MouseEvent: ${e is MouseEvent}"""); // TRACE%
    if (e is MouseEvent) {
      /*%TRACE3*/ print("""(4> 7/9/14): isPointInWidget(e.client): ${isPointInWidget(e.client)}"""); // TRACE%
    }
    /*%TRACE3*/ print("""(4> 7/9/14): this == e.target: ${this == e.target}"""); // TRACE%
    /*%TRACE3*/ print("""(4> 7/9/14): this.contains(e.target): ${this.contains(e.target)}"""); // TRACE%
    /*%TRACE3*/ print("""(4> 7/9/14): shadowRoot.contains(e.target): ${shadowRoot.contains(e.target)}"""); // TRACE%
    /*%TRACE3*/ print("""(4> 7/9/14): e.target: ${e.target.runtimeType}"""); // TRACE%
    /*%TRACE3*/ print("""(4> 7/9/14): e.target: ${e.target.id}"""); // TRACE%
    /*%TRACE3*/ print("""(4> 7/9/14): this: ${this.runtimeType}"""); // TRACE%
    /*%TRACE3*/ print("""(4> 7/9/14): this: ${this.id}"""); // TRACE%
    return
        (e is MouseEvent && isPointInWidget(e.client)) ||
        this == e.target ||
        this.contains(e.target) ||
        shadowRoot.contains(e.target);
  }

  static List<StreamSubscription> addEventHandlers(
      Iterable<Stream<Event>> eventStreams,
      Function handler,
      {bool capture: false}) {
    final List<StreamSubscription> eventSubs = [];
    eventStreams.forEach((stream) {
      if (capture) {
        eventSubs.add(stream.capture(handler));
      } else {
        eventSubs.add(stream.listen(handler));
      }
    });
    return eventSubs;
  }

  static void removeEventHandlers(List<StreamSubscription> eventSubs) {
    eventSubs..forEach((sub) => sub.cancel())..clear();
  }

  /**
   * Find a <content> element using a CSS selector and expand it, and any
   * recursively nested <content> elements distributed from light DOM as a result
   * of multi-level element embedding, with their children.
   */
  Iterable<Node> getExpandedDistributedNodes(String contentSelector) {
    final ContentElement content = shadowRoot.querySelector(contentSelector);
    return inlineNestedContentNodes(content);
  }

  /**
   * Inline a given <content> element, and any recursively nested <content> elements
   * distributed from light DOM as a result of multi-level element embedding, with
   * their children.
   */
  static Iterable<Node> inlineNestedContentNodes(ContentElement content) {
    final List<Node> dn = content.getDistributedNodes();
    final Iterable<Node> fdn = dn.where(
        (Node e) => (e is Element) && e.localName != "template");
    final Iterable<Node> edn = fdn.expand(
        (Node e) => e is ContentElement ? inlineNestedContentNodes(e) : [e]);
    return edn;
  }

  /**
   * Certain kinds of elements, e.g. <div>, by default do not accept keyboard
   * events. Assinging tabIndex to them makes them keyboard-focusable, and
   * therefore accepting keyboard events.
   */
  static void enableKeyboardEvents(Element elt) {
    if (elt != null && (elt.tabIndex == null || elt.tabIndex < 0)) {
      elt.tabIndex = 0;
    }
  }
}
