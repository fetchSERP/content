import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["message"]
  static values = { 
    type: String,
    message: String,
    duration: { type: Number, default: 5000 }
  }

  connect() {
    this.show();
  }

  show() {
    // Add the notification with slide-in animation
    this.element.classList.remove("translate-x-full", "opacity-0");
    this.element.classList.add("translate-x-0", "opacity-100");
    
    // Auto-dismiss after duration
    if (this.durationValue > 0) {
      this.timeoutId = setTimeout(() => {
        this.dismiss();
      }, this.durationValue);
    }
  }

  dismiss() {
    // Clear timeout if manually dismissed
    if (this.timeoutId) {
      clearTimeout(this.timeoutId);
    }
    
    // Add slide-out animation
    this.element.classList.remove("translate-x-0", "opacity-100");
    this.element.classList.add("translate-x-full", "opacity-0");
    
    // Remove element after animation completes
    setTimeout(() => {
      if (this.element.parentNode) {
        this.element.remove();
      }
    }, 300);
  }

  disconnect() {
    if (this.timeoutId) {
      clearTimeout(this.timeoutId);
    }
  }
} 