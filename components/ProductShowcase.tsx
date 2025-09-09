export default function ProductShowcase() {
  const products = [
    {
      name: "Classic Black Dress Socks",
      description: "Perfect for business and formal occasions",
      price: "$24.99"
    },
    {
      name: "Athletic Black Socks",
      description: "Moisture-wicking technology for active lifestyles",
      price: "$19.99"
    },
    {
      name: "Luxury Merino Wool Socks",
      description: "Premium merino wool for ultimate comfort",
      price: "$34.99"
    },
    {
      name: "Bamboo Black Socks",
      description: "Eco-friendly bamboo fiber, naturally antibacterial",
      price: "$27.99"
    },
    {
      name: "Compression Black Socks",
      description: "Medical-grade compression for better circulation",
      price: "$29.99"
    },
    {
      name: "No-Show Black Socks",
      description: "Invisible comfort for casual and athletic wear",
      price: "$16.99"
    }
  ]

  return (
    <section className="showcase" id="products">
      <div className="showcase-content">
        <h2>Our Premium Collection</h2>
        <p>
          From business meetings to weekend adventures, we have the perfect 
          black socks for every occasion.
        </p>
        <div className="product-grid">
          {products.map((product, index) => (
            <div key={index} className="product-card">
              <div className="product-image">🧦</div>
              <div className="product-info">
                <h3>{product.name}</h3>
                <p>{product.description}</p>
                <div className="price">{product.price}</div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}