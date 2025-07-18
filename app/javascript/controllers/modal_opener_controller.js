import { Controller } from "@hotwired/stimulus"
import { Application } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    url: String
  }

  connect() {
    // Controller connected
  }

  async open(event) {
    event.preventDefault()

    // Remove any existing modals first
    const existingModal = document.getElementById("modal");
    if (existingModal) {
      existingModal.remove();
    }
    
    const response = await fetch(this.urlValue, {
      headers: {
        "Accept": "text/vnd.turbo-stream.html"
      }
    })
    
    const text = await response.text()
    
    // Parse and examine the turbo streams
    const parser = new DOMParser();
    const doc = parser.parseFromString(text, 'text/html');
    const turboStreams = doc.querySelectorAll('turbo-stream');
    
    // Manual processing
    turboStreams.forEach((stream, index) => {
      const action = stream.getAttribute('action');
      const target = stream.getAttribute('target');
      const template = stream.querySelector('template');
      
      if (template && target) {
        const content = template.content.cloneNode(true);
        
        if (action === 'append') {
          const targetElement = target === 'body' ? document.body : document.querySelector(target);
          if (targetElement) {
            targetElement.appendChild(content);
            
            // Initialize Stimulus controllers for new elements
            if (window.Stimulus && window.Stimulus.start) {
              window.Stimulus.start();
            }
            
            // Initialize Lucide icons
            if (window.lucide) {
              window.lucide.createIcons();
            }
          }
        } else if (action === 'remove') {
          const elementToRemove = document.getElementById(target.replace('#', ''));
          if (elementToRemove) {
            elementToRemove.remove();
          }
        }
      }
    });
  }
} 