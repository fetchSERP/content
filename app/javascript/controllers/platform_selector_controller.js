import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { contentId: String, newForm: Boolean }

  updatePrompts(event) {
    const platform = event.target.value // Use the radio button value directly
    
    // Determine the URL based on the current path and whether this is a new form or edit form
    let url
    const currentPath = window.location.pathname
    
    if (currentPath.includes('/recurring_social_media_contents')) {
      // Recurring social media contents routes
      if (this.newFormValue || currentPath.includes('/new')) {
        url = `/app/recurring_social_media_contents/update_prompts_for_new?platform=${platform}`
      } else {
        const contentId = this.contentIdValue
        url = `/app/recurring_social_media_contents/${contentId}/update_prompts?platform=${platform}`
      }
    } else {
      // Regular social media contents routes
      if (this.newFormValue || currentPath.includes('/new')) {
        url = `/app/social_media_contents/update_prompts_for_new?platform=${platform}`
      } else {
        const contentId = this.contentIdValue
        url = `/app/social_media_contents/${contentId}/update_prompts?platform=${platform}`
      }
    }
    
    fetch(url, {
      method: 'GET',
      headers: {
        'Accept': 'text/vnd.turbo-stream.html',
        'X-Requested-With': 'XMLHttpRequest'
      }
    })
    .then(response => {
      if (response.ok) {
        return response.text()
      }
      throw new Error('Network response was not ok')
    })
    .then(html => {
      Turbo.renderStreamMessage(html)
    })
    .catch(error => {
      console.error('Error updating prompts:', error)
    })
  }
} 