import { Controller } from "@hotwired/stimulus"

// Stimulus controller: attaches Choices.js to a <select>
// Usage: add data-controller="choices-select" to the <select>
export default class extends Controller {
  connect() {
    // Avoid double-initialisation
    if (this.element._choicesInstance) return

    this.load()
  }

  async load() {
    const module = await import("choices.js")
    const Choices = module.default || module
    // eslint-disable-next-line new-cap
    const instance = new Choices(this.element, {
      searchEnabled: true,
      itemSelectText: "",
      allowHTML: true,
      searchResultLimit: -1,
      shouldSort: true,
      // searchFields: ['label', 'value', 'customProperties', 'groupLabel'],
      fuseOptions: {
        threshold: 0.3,
        keys: [
          'label',
          'value',
          'customProperties',
          'groupLabel'
        ],
      }
    })
    this.element._choicesInstance = instance
    this.choices = instance
  }

  disconnect() {
    const instance = this.element._choicesInstance
    if (instance) {
      try { instance.destroy() } catch (_) {}
      delete this.element._choicesInstance
    }
  }
} 