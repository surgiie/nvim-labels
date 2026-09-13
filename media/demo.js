class ShoppingCart {
  constructor(taxRate) {
    this.taxRate = taxRate
    this.cartItems = []
  }

  addItem(productName, unitPrice, quantity) {
    this.cartItems.push({ productName, unitPrice, quantity })
  }

  calculateTotalPrice() {
    let total_price = 0
    for (const item of this.cartItems) {
      total_price += item.unitPrice * item.quantity
    }
    return total_price * (1 + this.taxRate)
  }

  formatReceipt() {
    const lines = this.cartItems.map((item) => {
      return `${item.productName} x${item.quantity}`
    })
    return lines.join("\n")
  }
}

const shoppingCart = new ShoppingCart(0.0825)
shoppingCart.addItem("Coffee Mug", 12.99, 2)
shoppingCart.addItem("Desk Lamp", 24.5, 1)

console.log(shoppingCart.formatReceipt())
console.log(shoppingCart.calculateTotalPrice())
