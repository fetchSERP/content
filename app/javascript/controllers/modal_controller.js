import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Allow closing with the Esc key
    this.element.focus();
  }

  close() {
    this.element.remove();
  }

  handleKeydown(event) {
    if (event.key === "Escape") {
      this.close();
    }
  }

  closeOnBackgroundClick(event) {
    if (event.target === this.element) {
      this.close();
    }
  }
} 