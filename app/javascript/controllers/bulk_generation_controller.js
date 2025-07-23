import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["selectAll", "keywordsContainer", "submit"]

  connect() {
    this.updateSubmitState()
    this.updateDomainCheckboxes()
  }

  toggleSelectAll(event) {
    const checked = event.target.checked
    this.keywordsContainerTarget.querySelectorAll('input[type="checkbox"][name="keyword_ids[]"]').forEach(cb => {
      cb.checked = checked
    })
    this.updateDomainCheckboxes()
    this.updateSubmitState()
  }

  toggleKeyword() {
    this.updateSelectAllCheckbox()
    this.updateDomainCheckboxes()
    this.updateSubmitState()
  }

  toggleDomain(event) {
    const domainCheckbox = event.target
    const domainId = domainCheckbox.dataset.domain
    const checked = domainCheckbox.checked
    
    // Find all keyword checkboxes for this domain
    const domainKeywords = this.keywordsContainerTarget.querySelectorAll(`input[type="checkbox"][name="keyword_ids[]"][data-domain-id="${domainId}"]`)
    
    // Set all keywords for this domain to the same state as the domain checkbox
    domainKeywords.forEach(cb => {
      cb.checked = checked
    })
    
    // Update other checkboxes
    this.updateSelectAllCheckbox()
    this.updateSubmitState()
  }

  updateDomainCheckboxes() {
    // Update each domain checkbox based on its keywords
    const domainCheckboxes = this.element.querySelectorAll('input[type="checkbox"][data-domain]')
    
    domainCheckboxes.forEach(domainCheckbox => {
      const domainId = domainCheckbox.dataset.domain
      const domainKeywords = this.keywordsContainerTarget.querySelectorAll(`input[type="checkbox"][name="keyword_ids[]"][data-domain-id="${domainId}"]`)
      const checkedKeywords = this.keywordsContainerTarget.querySelectorAll(`input[type="checkbox"][name="keyword_ids[]"][data-domain-id="${domainId}"]:checked`)
      
      if (checkedKeywords.length === 0) {
        domainCheckbox.checked = false
        domainCheckbox.indeterminate = false
      } else if (checkedKeywords.length === domainKeywords.length) {
        domainCheckbox.checked = true
        domainCheckbox.indeterminate = false
      } else {
        domainCheckbox.checked = false
        domainCheckbox.indeterminate = true
      }
    })
  }

  updateSelectAllCheckbox() {
    const allCheckboxes = this.keywordsContainerTarget.querySelectorAll('input[type="checkbox"][name="keyword_ids[]"]')
    const checkedCount = Array.from(allCheckboxes).filter(cb => cb.checked).length
    
    if (checkedCount === 0) {
      this.selectAllTarget.checked = false
      this.selectAllTarget.indeterminate = false
    } else if (checkedCount === allCheckboxes.length) {
      this.selectAllTarget.checked = true
      this.selectAllTarget.indeterminate = false
    } else {
      this.selectAllTarget.checked = false
      this.selectAllTarget.indeterminate = true
    }
  }

  updateSubmitState() {
    const anyChecked = this.keywordsContainerTarget.querySelector('input[type="checkbox"][name="keyword_ids[]"]:checked')
    this.submitTarget.disabled = !anyChecked
  }
} 