// frozen_string_literal: true

import { Controller } from "@hotwired/stimulus"

// Courier Tracking Controller
// Handles AJAX interactions for Pathao Courier integration
export default class extends Controller {
  static targets = [
    "pathaoOptions",
    "calculateBtn",
    "costBreakdown",
    "shippingCost",
    "codFee",
    "totalCollect",
    "estimatedDelivery",
    "trackingNumber",
    "note",
    "confirmBtn",
    "orderData"
  ]

  static values = {
    orderId: String,
    csrfToken: String
  }

  connect() {
    this.loadOrderData()
    this.checkExistingTracking()
  }

  loadOrderData() {
    try {
      const data = JSON.parse(this.orderDataTarget.textContent)
      this.orderIdValue = data.orderId
      this.csrfTokenValue = data.csrfToken
    } catch (e) {
      console.error("Failed to load order data:", e)
    }
  }

  checkExistingTracking() {
    // Check if there's existing tracking info
    fetch(this.trackingUrl(), {
      headers: {
        "Accept": "application/json",
        "X-CSRF-Token": this.csrfTokenValue
      }
    })
    .then(response => response.json())
    .then(data => {
      if (data.success && data.tracking_info) {
        this.showExistingTracking(data.tracking_info)
      }
    })
    .catch(error => console.error("Failed to load tracking:", error))
  }

  showExistingTracking(info) {
    if (info.consignment_id && this.hasTrackingNumberTarget) {
      this.trackingNumberTarget.value = info.consignment_id
    }
  }

  selectCourier(event) {
    const value = event.target.value
    if (value === "pathao") {
      this.pathaoOptionsTarget.style.display = "block"
    } else {
      this.pathaoOptionsTarget.style.display = "none"
    }
  }

  selectDeliveryType(event) {
    // Just update the selected value, no immediate action needed
  }

  async calculateCost(event) {
    event.preventDefault()
    console.log("Calculating")
    const deliveryType = document.querySelector('input[name="delivery_type"]:checked')?.value || 48
    const itemWeight = this.itemWeightTarget?.value || 500

    this.showLoading(this.calculateBtnTarget, "Calculating...")

    try {
      const response = await fetch(this.estimateCostUrl(), {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": this.csrfTokenValue
        },
        body: JSON.stringify({
          delivery_type: parseInt(deliveryType),
          item_weight: parseInt(itemWeight)
        })
      })

      const data = await response.json()

      if (data.success) {
        this.displayCostBreakdown(data.cost)
      } else {
        this.showError(data.error || "Failed to calculate cost")
      }
    } catch (error) {
      console.error("Cost calculation failed:", error)
      this.showError("Network error. Please try again.")
    } finally {
      this.hideLoading(this.calculateBtnTarget, '<i class="bi bi-calculator"></i> Calculate Total COD')
    }
  }

  displayCostBreakdown(cost) {
    this.costBreakdownTarget.style.display = "block"
    this.shippingCostTarget.textContent = `৳${cost.price}`
    this.codFeeTarget.textContent = `৳${Math.round(cost.price * cost.cod_percentage / 100)}`
    this.totalCollectTarget.textContent = `৳${cost.final_price}`
    this.estimatedDeliveryTarget.textContent = cost.estimated_delivery
  }

  async confirmShipment(event) {
    event.preventDefault()

    const deliveryType = document.querySelector('input[name="delivery_type"]:checked')?.value || 48
    const itemWeight = this.itemWeightTarget?.value || 500
    const note = this.noteTarget?.value || ""

    if (!confirm("Are you sure you want to confirm this shipment?")) {
      return
    }

    this.showLoading(this.confirmBtnTarget, "Confirming...")

    try {
      const response = await fetch(this.confirmUrl(), {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": this.csrfTokenValue
        },
        body: JSON.stringify({
          delivery_type: parseInt(deliveryType),
          item_weight: parseInt(itemWeight),
          note: note
        })
      })

      const data = await response.json()

      if (data.success) {
        this.showSuccess("Shipment confirmed successfully!")
        this.updateTrackingNumber(data.tracking_info.tracking_display)
        this.confirmBtnTarget.disabled = true
        this.confirmBtnTarget.innerHTML = '<i class="bi bi-check-circle"></i> Confirmed'
      } else {
        this.showError(data.error || "Failed to confirm shipment")
      }
    } catch (error) {
      console.error("Confirmation failed:", error)
      this.showError("Network error. Please try again.")
    } finally {
      this.hideLoading(this.confirmBtnTarget, '<i class="bi bi-check-circle"></i> Confirm & Save')
    }
  }

  updateTrackingNumber(trackingNumber) {
    if (!this.hasTrackingNumberTarget) {
      // Create tracking number input if it doesn't exist
      const container = this.costBreakdownTarget.parentNode
      const trackingDiv = document.createElement("div")
      trackingDiv.className = "mb-3"
      trackingDiv.innerHTML = `
        <label class="form-label fw-bold">Tracking Number</label>
        <div class="input-group">
          <input type="text" class="form-control" id="tracking-number"
                 value="${trackingNumber}" readonly
                 data-courier-tracking-target="trackingNumber">
          <button class="btn btn-outline-secondary" type="button"
                  data-action="click->courier-tracking#copyTrackingNumber"
                  title="Copy to clipboard">
            <i class="bi bi-clipboard"></i>
          </button>
        </div>
      `
      container.insertBefore(trackingDiv, this.noteTarget?.parentNode)
    } else {
      this.trackingNumberTarget.value = trackingNumber
    }
  }

  copyTrackingNumber(event) {
    event.preventDefault()

    const trackingNumber = this.trackingNumberTarget?.value
    if (!trackingNumber) {
      this.showError("No tracking number to copy")
      return
    }

    navigator.clipboard.writeText(trackingNumber).then(() => {
      this.showSuccess("Tracking number copied to clipboard!")
    }).catch(err => {
      console.error("Failed to copy:", err)
      // Fallback: select the text
      this.trackingNumberTarget.select()
      this.showError("Press Ctrl+C to copy")
    })
  }

  // Helper methods
  estimateCostUrl() {
    return `/admin/orders/${this.orderIdValue}/courier/estimate_cost`
  }

  confirmUrl() {
    return `/admin/orders/${this.orderIdValue}/courier/confirm`
  }

  trackingUrl() {
    return `/admin/orders/${this.orderIdValue}/courier/tracking`
  }

  showLoading(button, text) {
    button.disabled = true
    button.innerHTML = `<span class="spinner-border spinner-border-sm" role="status"></span> ${text}`
  }

  hideLoading(button, originalHtml) {
    button.disabled = false
    button.innerHTML = originalHtml
  }

  showError(message) {
    // Use Spree's flash messages if available, otherwise alert
    if (typeof Spree !== "undefined" && Spree.show_flash) {
      Spree.show_flash("error", message)
    } else {
      alert(message)
    }
  }

  showSuccess(message) {
    if (typeof Spree !== "undefined" && Spree.show_flash) {
      Spree.show_flash("success", message)
    } else {
      alert(message)
    }
  }
}
