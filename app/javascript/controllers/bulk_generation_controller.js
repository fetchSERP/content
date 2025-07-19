import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["selectAll", "keywordsContainer", "submit"]

  connect() {
    this.updateSubmitState()
  }

  toggleSelectAll(event) {
    const checked = event.target.checked
    this.keywordsContainerTarget.querySelectorAll('input[type="checkbox"][name="keyword_ids[]"]').forEach(cb => {
      cb.checked = checked
    })
    this.updateSubmitState()
  }

  toggleKeyword() {
    const allCheckboxes = this.keywordsContainerTarget.querySelectorAll('input[type="checkbox"][name="keyword_ids[]"]')
    const checkedCount  = Array.from(allCheckboxes).filter(cb => cb.checked).length
    this.selectAllTarget.checked = checkedCount === allCheckboxes.length
    this.updateSubmitState()
  }

  updateSubmitState() {
    const anyChecked = this.keywordsContainerTarget.querySelector('input[type="checkbox"][name="keyword_ids[]"]:checked')
    this.submitTarget.disabled = !anyChecked
  }
} 