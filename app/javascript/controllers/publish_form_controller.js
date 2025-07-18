import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  async submit(event) {
    event.preventDefault()
    
    const formData = new FormData(this.element)
    const url = this.element.action
    
    try {
      const response = await fetch(url, {
        method: 'PATCH',
        headers: {
          "Accept": "text/vnd.turbo-stream.html",
          "X-Requested-With": "XMLHttpRequest"
        },
        body: formData
      })
      
      if (response.ok) {
        const text = await response.text()
        
        // Parse and process turbo streams manually
        const parser = new DOMParser();
        const doc = parser.parseFromString(text, 'text/html');
        const turboStreams = doc.querySelectorAll('turbo-stream');
        
        turboStreams.forEach((stream, index) => {
          const action = stream.getAttribute('action');
          const target = stream.getAttribute('target');
          const template = stream.querySelector('template');
          
          if (action === 'remove' && target) {
            const elementToRemove = document.getElementById(target);
            if (elementToRemove) {
              elementToRemove.remove();
            }
          } else if (template && target && action === 'append') {
            const content = template.content.cloneNode(true);
            
            const targetElement = target === 'body' ? document.body : document.querySelector(target);
            if (targetElement) {
              targetElement.appendChild(content);
              
              // Initialize Stimulus controllers for notifications
              if (window.Stimulus && window.Stimulus.start) {
                window.Stimulus.start();
              }
              
              // Initialize Lucide icons
              if (window.lucide) {
                window.lucide.createIcons();
              }
            }
          }
        });
      }
    } catch (error) {
      console.error("Error submitting publish form:", error);
    }
  }
} 