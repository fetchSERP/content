import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { contentId: String, newForm: Boolean }

  updatePrompts(event) {
    const platform = event.target.value // Use the radio button value directly
    
    // Determine the URL based on the current path and whether this is a new form or edit form
    let promptsUrl, authProvidersUrl
    const currentPath = window.location.pathname
    
    if (currentPath.includes('/recurring_social_media_contents')) {
      // Recurring social media contents routes
      if (this.newFormValue || currentPath.includes('/new')) {
        promptsUrl = `/app/recurring_social_media_contents/update_prompts_for_new?platform=${platform}`
        authProvidersUrl = `/app/recurring_social_media_contents/update_authentication_providers_for_new?platform=${platform}`
      } else {
        const contentId = this.contentIdValue
        promptsUrl = `/app/recurring_social_media_contents/${contentId}/update_prompts?platform=${platform}`
        authProvidersUrl = `/app/recurring_social_media_contents/${contentId}/update_authentication_providers?platform=${platform}`
      }
    } else {
      // Regular social media contents routes
      if (this.newFormValue || currentPath.includes('/new')) {
        promptsUrl = `/app/social_media_contents/update_prompts_for_new?platform=${platform}`
      } else {
        const contentId = this.contentIdValue
        promptsUrl = `/app/social_media_contents/${contentId}/update_prompts?platform=${platform}`
      }
    }
    
    // Update prompts
    this.fetchAndRender(promptsUrl)
    
    // Update authentication providers (only for recurring social media contents)
    if (authProvidersUrl) {
      this.fetchAndRender(authProvidersUrl)
    }
  }

  fetchAndRender(url) {
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
      console.error('Error updating content:', error)
    })
  }
} 