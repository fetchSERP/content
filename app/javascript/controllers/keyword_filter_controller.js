import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = []

  connect() {
    console.log("KeywordFilter controller connected")
    this.totalKeywords = this.element.querySelectorAll('[data-keyword-item]').length
    console.log("Total keywords found:", this.totalKeywords)
  }

  filter(event) {
    console.log("Filter method called with:", event.target.value)
    const searchTerm = event.target.value.toLowerCase().trim()
    const keywordItems = this.element.querySelectorAll('[data-keyword-item]')
    const domainContainers = this.element.querySelectorAll('[data-domain-container]')
    
    console.log("Found keyword items:", keywordItems.length)
    console.log("Found domain containers:", domainContainers.length)
    
    let visibleCount = 0
    const domainCounts = {}

    // Filter keyword items
    keywordItems.forEach(item => {
      const keywordName = item.dataset.keywordName
      const domainId = item.dataset.keywordDomain
      
      if (!domainCounts[domainId]) {
        domainCounts[domainId] = 0
      }

      if (searchTerm === '' || keywordName.includes(searchTerm)) {
        item.style.display = 'block'
        visibleCount++
        domainCounts[domainId]++
      } else {
        item.style.display = 'none'
      }
    })

    console.log("Visible count:", visibleCount)

    // Update domain containers visibility and counts
    domainContainers.forEach(container => {
      const domainId = container.dataset.domainContainer
      const count = domainCounts[domainId] || 0
      const countElement = container.querySelector(`[data-domain-count="${domainId}"]`)
      
      if (count > 0) {
        container.style.display = 'block'
        if (countElement) {
          countElement.textContent = count === 1 ? '1 keyword' : `${count} keywords`
        }
      } else {
        container.style.display = 'none'
      }
    })

    // Update total keyword count
    const countElement = document.getElementById('keyword-count')
    if (countElement) {
      if (searchTerm === '') {
        countElement.textContent = this.totalKeywords === 1 ? '1 keyword available' : `${this.totalKeywords} keywords available`
      } else {
        countElement.textContent = visibleCount === 1 ? '1 keyword found' : `${visibleCount} keywords found`
      }
    }

    // Show/hide "no results" message
    this.toggleNoResultsMessage(visibleCount === 0 && searchTerm !== '')
  }

  toggleNoResultsMessage(show) {
    let noResultsElement = this.element.querySelector('#no-search-results')
    
    if (show && !noResultsElement) {
      // Create no results message
      noResultsElement = document.createElement('div')
      noResultsElement.id = 'no-search-results'
      noResultsElement.className = 'text-center py-8'
      noResultsElement.innerHTML = `
        <div class="flex flex-col items-center">
          <i data-lucide="search-x" class="h-12 w-12 text-gray-400 mb-3"></i>
          <h3 class="text-lg font-medium text-gray-300 mb-1">No keywords found</h3>
          <p class="text-gray-400 text-sm">Try adjusting your search terms</p>
        </div>
      `
      
      // Insert after the search box
      const searchContainer = this.element.querySelector('#keyword-search').closest('.mb-4')
      searchContainer.parentNode.insertBefore(noResultsElement, searchContainer.nextSibling)
      
      // Initialize Lucide icons for the new element
      if (window.lucide) {
        window.lucide.createIcons({ 
          element: noResultsElement 
        })
      }
    } else if (!show && noResultsElement) {
      noResultsElement.remove()
    }
  }
} 