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
    this.updateLongTailGroupCheckboxes()
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
    
    // Find all keyword checkboxes for this domain (both regular and long tail)
    const domainKeywords = this.keywordsContainerTarget.querySelectorAll(`input[type="checkbox"][name="keyword_ids[]"][data-domain-id="${domainId}"]`)
    const domainLongTailKeywords = this.keywordsContainerTarget.querySelectorAll(`input[type="checkbox"][name="keyword_ids[]"][data-pillar-keyword-id]`)
    
    // Set all keywords for this domain to the same state as the domain checkbox
    domainKeywords.forEach(cb => {
      cb.checked = checked
    })
    
    // Also toggle long tail keywords for pillar keywords in this domain
    domainLongTailKeywords.forEach(cb => {
      const pillarKeywordId = cb.dataset.pillarKeywordId
      const pillarKeyword = this.keywordsContainerTarget.querySelector(`input[name="keyword_ids[]"][value="${pillarKeywordId}"]`)
      if (pillarKeyword && pillarKeyword.dataset.domainId === domainId) {
        cb.checked = checked
      }
    })
    
    // Update other checkboxes
    this.updateSelectAllCheckbox()
    this.updateLongTailGroupCheckboxes()
    this.updateSubmitState()
  }

  toggleLongTailGroup(event) {
    const groupCheckbox = event.target
    const pillarKeywordId = groupCheckbox.dataset.pillarKeywordId
    const checked = groupCheckbox.checked
    
    // Find all long tail keyword checkboxes for this pillar keyword
    const longTailKeywords = this.element.querySelectorAll(`input[type="checkbox"][name="keyword_ids[]"][data-pillar-keyword-id="${pillarKeywordId}"]`)
    
    // Set all long tail keywords for this pillar keyword to the same state
    longTailKeywords.forEach(cb => {
      cb.checked = checked
    })
    
    this.updateSelectAllCheckbox()
    this.updateSubmitState()
  }

  toggleLongTailKeyword() {
    this.updateSelectAllCheckbox()
    this.updateLongTailGroupCheckboxes()
    this.updateSubmitState()
  }

  updateDomainCheckboxes() {
    // Update each domain checkbox based on its keywords
    const domainCheckboxes = this.element.querySelectorAll('input[type="checkbox"][data-domain]')
    
    domainCheckboxes.forEach(domainCheckbox => {
      const domainId = domainCheckbox.dataset.domain
      const domainKeywords = this.keywordsContainerTarget.querySelectorAll(`input[type="checkbox"][name="keyword_ids[]"][data-domain-id="${domainId}"]`)
      const checkedKeywords = this.keywordsContainerTarget.querySelectorAll(`input[type="checkbox"][name="keyword_ids[]"][data-domain-id="${domainId}"]:checked`)
      
      // Also count long tail keywords for this domain
      const domainLongTailKeywords = Array.from(this.keywordsContainerTarget.querySelectorAll(`input[type="checkbox"][name="keyword_ids[]"][data-pillar-keyword-id]`)).filter(cb => {
        const pillarKeywordId = cb.dataset.pillarKeywordId
        const pillarKeyword = this.keywordsContainerTarget.querySelector(`input[name="keyword_ids[]"][value="${pillarKeywordId}"]`)
        return pillarKeyword && pillarKeyword.dataset.domainId === domainId
      })
      
      const checkedLongTailKeywords = domainLongTailKeywords.filter(cb => cb.checked)
      
      const totalKeywords = domainKeywords.length + domainLongTailKeywords.length
      const totalChecked = checkedKeywords.length + checkedLongTailKeywords.length
      
      if (totalChecked === 0) {
        domainCheckbox.checked = false
        domainCheckbox.indeterminate = false
      } else if (totalChecked === totalKeywords) {
        domainCheckbox.checked = true
        domainCheckbox.indeterminate = false
      } else {
        domainCheckbox.checked = false
        domainCheckbox.indeterminate = true
      }
    })
  }

  updateLongTailGroupCheckboxes() {
    // Update each long tail group checkbox based on its keywords
    const groupCheckboxes = this.element.querySelectorAll('input[type="checkbox"][data-pillar-keyword-id]')
    
    // Group by pillar keyword ID
    const pillarKeywordIds = [...new Set(Array.from(groupCheckboxes).map(cb => cb.dataset.pillarKeywordId))]
    
    pillarKeywordIds.forEach(pillarKeywordId => {
      const groupCheckbox = this.element.querySelector(`input[id="select_all_longtail_${pillarKeywordId}"]`)
      if (!groupCheckbox) return
      
      const longTailKeywords = this.element.querySelectorAll(`input[type="checkbox"][name="keyword_ids[]"][data-pillar-keyword-id="${pillarKeywordId}"]`)
      const checkedLongTailKeywords = this.element.querySelectorAll(`input[type="checkbox"][name="keyword_ids[]"][data-pillar-keyword-id="${pillarKeywordId}"]:checked`)
      
      if (checkedLongTailKeywords.length === 0) {
        groupCheckbox.checked = false
        groupCheckbox.indeterminate = false
      } else if (checkedLongTailKeywords.length === longTailKeywords.length) {
        groupCheckbox.checked = true
        groupCheckbox.indeterminate = false
      } else {
        groupCheckbox.checked = false
        groupCheckbox.indeterminate = true
      }
    })
  }

  updateSelectAllCheckbox() {
    // Only update if selectAll target exists
    if (!this.hasSelectAllTarget) return
    
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
    // Only update if submit target exists
    if (!this.hasSubmitTarget) return
    
    const anyChecked = this.keywordsContainerTarget.querySelector('input[type="checkbox"][name="keyword_ids[]"]:checked')
    this.submitTarget.disabled = !anyChecked
  }
} 