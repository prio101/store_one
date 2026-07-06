# frozen_string_literal: true
#
# Development seed data for minimeshop.net
# Bangladesh-focused e-commerce dataset
#
# Usage: docker compose exec web bin/rails db:seed
# Safe to re-run (idempotent via find_or_create_by / update)
#

# ── 1. Spree default data (countries, states, etc.) ──────────────────────
Spree::Core::Engine.load_seed if defined?(Spree::Core)

puts "🌱 Seeding minimeshop.net development data..."

# ── 2. Roles ─────────────────────────────────────────────────────────────
admin_role = Spree::Role.find_or_create_by!(name: 'admin')
user_role  = Spree::Role.find_or_create_by!(name: 'user')
puts "  ✓ Roles"

# ── 3. Admin user ────────────────────────────────────────────────────────
admin = Spree::AdminUser.find_or_initialize_by(email: 'admin@minimeshop.net')
if admin.new_record?
  admin.password = 'password123'
  admin.password_confirmation = 'password123'
  admin.first_name = 'Admin'
  admin.last_name = 'User'
  admin.save!
end
admin.spree_roles << admin_role unless admin.spree_roles.include?(admin_role)
puts "  ✓ Admin user (admin@minimeshop.net / password123)"

# ── 4. Store configuration ──────────────────────────────────────────────
bangladesh = Spree::Country.find_by!(iso: 'BD')

store = Spree::Store.first
store.update!(
  name:                  'MiniMeShop',
  url:                   'minimeshop.net',
  mail_from_address:     'noreply@minimeshop.net',
  default_currency:      'BDT',
  supported_currencies:  'BDT,USD',
  default_country_id:    bangladesh.id,
  default_locale:        'en',
  description:           'Bangladesh\'s one-stop online shop for electronics, fashion, and everyday essentials.',
  contact_phone:         '+880 1XXX-XXXXXX',
  customer_support_email:'support@minimeshop.net',
  meta_description:      'Shop electronics, fashion, and home essentials with fast delivery across Bangladesh.',
  meta_keywords:         'bangladesh, online shopping, electronics, fashion, ecommerce',
  seo_title:             'MiniMeShop - Online Shopping Bangladesh',
  facebook:              'https://facebook.com/minimeshop',
  instagram:             'https://instagram.com/minimeshop',
  twitter:               'https://twitter.com/minimeshop',
)
puts "  ✓ Store (MiniMeShop / minimeshop.net / BDT)"

# ── 5. Price list ───────────────────────────────────────────────────────
default_price_list = Spree::PriceList.find_or_create_by!(
  store: store,
  name: 'Default Prices',
  match_policy: 'all'
)
puts "  ✓ Default price list"

# ── 6. Stock location ───────────────────────────────────────────────────
stock_location = Spree::StockLocation.find_or_create_by!(
  name: 'Dhaka Warehouse',
  admin_name: 'DHK-WH-01',
  default: true,
  active: true,
  address1: '42 Ring Road, Banani',
  city: 'Dhaka',
  zipcode: '1213',
  country: bangladesh,
  phone: '+880 1XXX-XXXXXX',
  company: 'MiniMeShop Fulfillment',
  propagate_all_variants: true,
  backorderable_default: true,
)
puts "  ✓ Stock location (Dhaka Warehouse)"

# ── 7. Shipping category ────────────────────────────────────────────────
default_shipping_category = Spree::ShippingCategory.find_or_create_by!(name: 'Default')
heavy_shipping_category = Spree::ShippingCategory.find_or_create_by!(name: 'Heavy Goods')
puts "  ✓ Shipping categories"

# ── 8. Tax category ─────────────────────────────────────────────────────
default_tax_category = Spree::TaxCategory.find_or_create_by!(name: 'Default', is_default: true)
clothing_tax_category = Spree::TaxCategory.find_or_create_by!(name: 'Clothing')
electronics_tax_category = Spree::TaxCategory.find_or_create_by!(name: 'Electronics')
puts "  ✓ Tax categories"

# ── 9. Zones ────────────────────────────────────────────────────────────
bangladesh_zone = Spree::Zone.find_or_create_by!(name: 'Bangladesh') do |z|
  z.kind = 'country'
  z.default_tax = true
end
unless bangladesh_zone.zone_members.exists?(zoneable: bangladesh)
  bangladesh_zone.zone_members.create!(zoneable: bangladesh)
end

worldwide_zone = Spree::Zone.find_or_create_by!(name: 'Worldwide') do |z|
  z.kind = 'country'
  z.default_tax = false
end
# Add a few popular countries to Worldwide
%w[US IN PK LK NP].each do |iso|
  country = Spree::Country.find_by(iso: iso)
  next unless country
  worldwide_zone.zone_members.find_or_create_by!(zoneable: country)
end
puts "  ✓ Zones (Bangladesh, Worldwide)"

# ── 10. Tax rates ───────────────────────────────────────────────────────
Spree::TaxRate.find_or_create_by!(
  name: 'Bangladesh VAT 15%',
  zone: bangladesh_zone,
  amount: 0.15,
  tax_category: default_tax_category,
  included_in_price: false,
  show_rate_in_label: true,
) do |tr|
  tr.calculator = Spree::Calculator::DefaultTax.new
end
Spree::TaxRate.find_or_create_by!(
  name: 'Clothing VAT 10%',
  zone: bangladesh_zone,
  amount: 0.10,
  tax_category: clothing_tax_category,
  included_in_price: false,
  show_rate_in_label: true,
) do |tr|
  tr.calculator = Spree::Calculator::DefaultTax.new
end
puts "  ✓ Tax rates"

# ── 11. Shipping methods ────────────────────────────────────────────────
pathao_normal = Spree::ShippingMethod.find_or_create_by!(
  name: 'Pathao Courier - Normal',
  code: 'PATHAO_NORMAL',
  admin_name: 'Pathao Normal Delivery',
  cod: true,
  display_on: 'both',
) do |sm|
  sm.shipping_categories = [default_shipping_category]
  sm.zones = [bangladesh_zone]
  sm.calculator = Spree::Calculator::Shipping::FlatRate.new(preferred_amount: 60, preferred_currency: 'BDT')
end
pathao_normal.update_columns(
  estimated_transit_business_days_min: 2,
  estimated_transit_business_days_max: 5,
)

pathao_express = Spree::ShippingMethod.find_or_create_by!(
  name: 'Pathao Courier - Express',
  code: 'PATHAO_EXPRESS',
  admin_name: 'Pathao Express Delivery',
  cod: true,
  display_on: 'both',
) do |sm|
  sm.shipping_categories = [default_shipping_category]
  sm.zones = [bangladesh_zone]
  sm.calculator = Spree::Calculator::Shipping::FlatRate.new(preferred_amount: 120, preferred_currency: 'BDT')
end
pathao_express.update_columns(
  estimated_transit_business_days_min: 1,
  estimated_transit_business_days_max: 2,
)

free_shipping = Spree::ShippingMethod.find_or_create_by!(
  name: 'Free Shipping',
  code: 'FREE_SHIPPING',
  admin_name: 'Free Shipping (Dhaka only)',
  cod: false,
  display_on: 'both',
) do |sm|
  sm.shipping_categories = [default_shipping_category]
  sm.zones = [bangladesh_zone]
  sm.calculator = Spree::Calculator::Shipping::FlatRate.new(preferred_amount: 0, preferred_currency: 'BDT')
end

standard_intl = Spree::ShippingMethod.find_or_create_by!(
  name: 'International Standard',
  code: 'INTL_STANDARD',
  admin_name: 'International Standard Shipping',
  cod: false,
  display_on: 'both',
) do |sm|
  sm.shipping_categories = [heavy_shipping_category]
  sm.zones = [worldwide_zone]
  sm.calculator = Spree::Calculator::Shipping::FlatRate.new(preferred_amount: 2000, preferred_currency: 'BDT')
end
standard_intl.update_columns(
  estimated_transit_business_days_min: 7,
  estimated_transit_business_days_max: 21,
)
puts "  ✓ Shipping methods (Pathao Normal/Express, Free Shipping, International)"

# ── 12. Payment methods ─────────────────────────────────────────────────
cod_payment = Spree::PaymentMethod::CodPayment.find_or_create_by!(
  name: 'Cash on Delivery (COD)',
  description: 'Pay when your order arrives. Available within Bangladesh.',
  active: true,
  auto_capture: false,
  display_on: 'both',
  position: 1,
)
store.payment_methods << cod_payment unless store.payment_methods.include?(cod_payment)

bank_transfer = Spree::PaymentMethod::Check.find_or_create_by!(
  name: 'Bank Transfer / bKash / Nagad',
  description: 'Transfer via bank, bKash, or Nagad. Order ships after payment confirmation.',
  active: true,
  auto_capture: false,
  display_on: 'both',
  position: 2,
)
store.payment_methods << bank_transfer unless store.payment_methods.include?(bank_transfer)
puts "  ✓ Payment methods (COD, Bank Transfer/bKash/Nagad)"

# ── 13. Taxonomy & Taxons ──────────────────────────────────────────────
# Categories taxonomy
categories_taxonomy = Spree::Taxonomy.find_or_create_by!(name: 'Categories', store: store)

category_data = {
  'Electronics' => %w[Smartphones Laptops Tablets Audio Wearables],
  'Fashion'     => %w[Men Women Kids Accessories],
  'Home & Living' => %w[Furniture Kitchen Decor Lighting],
  'Beauty'      => %w[Skincare Makeup Haircare Fragrances],
  'Sports'      => %w[Fitness Cricket Running Footwear],
}

category_data.each_with_index do |(parent_name, children), p_idx|
  parent = Spree::Taxon.find_or_create_by!(
    name: parent_name,
    taxonomy: categories_taxonomy,
    permalink: "#{categories_taxonomy.root.permalink}/#{parent_name.parameterize}",
    parent: categories_taxonomy.root,
    position: p_idx,
  )
  children.each_with_index do |child_name, c_idx|
    Spree::Taxon.find_or_create_by!(
      name: child_name,
      taxonomy: categories_taxonomy,
      parent: parent,
      permalink: "#{categories_taxonomy.root.permalink}/#{parent_name.parameterize}/#{child_name.parameterize}",
      position: c_idx,
    )
  end
end

# Brands taxonomy
brands_taxonomy = Spree::Taxonomy.find_or_create_by!(name: 'Brands', store: store)

%w[Apple Samsung Xiaomi Sony Nike Adidas Walton Marvel Skyland Robi].each_with_index do |brand_name, idx|
  Spree::Taxon.find_or_create_by!(
    name: brand_name,
    taxonomy: brands_taxonomy,
    permalink: "#{brands_taxonomy.root.permalink}/#{brand_name.parameterize}",
    parent: brands_taxonomy.root,
    position: idx,
  )
end
puts "  ✓ Taxonomies & Taxons"

# ── 14. Option Types & Values ──────────────────────────────────────────
size_ot = Spree::OptionType.find_or_create_by!(name: 'size', presentation: 'Size', kind: 'dropdown')
color_ot = Spree::OptionType.find_or_create_by!(name: 'color', presentation: 'Color', kind: 'dropdown')

size_values = %w[XS S M L XL XXL]
size_values.each_with_index do |sz, idx|
  Spree::OptionValue.find_or_create_by!(name: sz.downcase, presentation: sz, option_type: size_ot, position: idx)
end

color_values = [
  { name: 'black', presentation: 'Black' },
  { name: 'white', presentation: 'White' },
  { name: 'blue', presentation: 'Blue' },
  { name: 'red', presentation: 'Red' },
  { name: 'navy', presentation: 'Navy' },
]
color_values.each_with_index do |cv, idx|
  Spree::OptionValue.find_or_create_by!(
    name: cv[:name], presentation: cv[:presentation], option_type: color_ot, position: idx
  )
end
puts "  ✓ Option types & values"

# ── 15. Products ────────────────────────────────────────────────────────
products_data = [
  {
    name: 'Samsung Galaxy A15 (6GB/128GB)',
    slug: 'samsung-galaxy-a15',
    description: '<p>Samsung Galaxy A15 with 6GB RAM and 128GB storage. Super AMOLED display, 50MP triple camera, and 5000mAh battery. Perfect for everyday use.</p>',
    sku: 'SAM-GAL-A15-128',
    price_bdt: 18_999,
    cost_price: 14_500,
    weight: 0.2,
    category_taxon: 'categories/electronics/smartphones',
    brand_taxon: 'brands/samsung',
    tax_category: electronics_tax_category,
    shipping_category: default_shipping_category,
    variants: [
      { sku: 'SAM-GAL-A15-128-BLK', color: 'Black', price_bdt: 18_999 },
      { sku: 'SAM-GAL-A15-128-BLU', color: 'Blue', price_bdt: 18_999 },
    ],
  },
  {
    name: 'Xiaomi Redmi Note 13 Pro (8GB/256GB)',
    slug: 'xiaomi-redmi-note-13-pro',
    description: '<p>Xiaomi Redmi Note 13 Pro with 8GB RAM and 256GB storage. 200MP camera, 120Hz AMOLED display, and fast charging support.</p>',
    sku: 'XIA-RMN13P-256',
    price_bdt: 27_999,
    cost_price: 22_000,
    weight: 0.19,
    category_taxon: 'categories/electronics/smartphones',
    brand_taxon: 'brands/xiaomi',
    tax_category: electronics_tax_category,
    shipping_category: default_shipping_category,
    variants: [
      { sku: 'XIA-RMN13P-256-BLK', color: 'Black', price_bdt: 27_999 },
      { sku: 'XIA-RMN13P-256-WHT', color: 'White', price_bdt: 27_999 },
    ],
  },
  {
    name: 'Walton Primo H8 Pro',
    slug: 'walton-primo-h8-pro',
    description: '<p>Bangladesh-made Walton Primo H8 Pro. 6.6" display, 50MP AI camera, 5000mAh battery with fast charging. Made in Bangladesh.</p>',
    sku: 'WLT-PRMH8P-64',
    price_bdt: 12_499,
    cost_price: 9_800,
    weight: 0.18,
    category_taxon: 'categories/electronics/smartphones',
    brand_taxon: 'brands/walton',
    tax_category: electronics_tax_category,
    shipping_category: default_shipping_category,
    variants: [
      { sku: 'WLT-PRMH8P-64-BLK', color: 'Black', price_bdt: 12_499 },
      { sku: 'WLT-PRMH8P-64-BLU', color: 'Blue', price_bdt: 12_499 },
    ],
  },
  {
    name: 'Apple AirPods Pro (2nd Gen)',
    slug: 'apple-airpods-pro-2nd-gen',
    description: '<p>Apple AirPods Pro 2nd generation with Active Noise Cancellation and Adaptive Transparency. Personalized Spatial Audio with dynamic head tracking.</p>',
    sku: 'APL-APP2G-WHT',
    price_bdt: 28_500,
    cost_price: 23_000,
    weight: 0.05,
    category_taxon: 'categories/electronics/audio',
    brand_taxon: 'brands/apple',
    tax_category: electronics_tax_category,
    shipping_category: default_shipping_category,
    variants: [
      { sku: 'APL-APP2G-WHT', color: 'White', price_bdt: 28_500 },
    ],
  },
  {
    name: 'Sony WH-1000XM5 Headphones',
    slug: 'sony-wh-1000xm5',
    description: '<p>Sony WH-1000XM5 wireless noise-cancelling headphones. Industry-leading noise cancellation, 30-hour battery life, and premium comfort.</p>',
    sku: 'SNY-WH1KXM5-BLK',
    price_bdt: 35_000,
    cost_price: 28_000,
    weight: 0.25,
    category_taxon: 'categories/electronics/audio',
    brand_taxon: 'brands/sony',
    tax_category: electronics_tax_category,
    shipping_category: default_shipping_category,
    variants: [
      { sku: 'SNY-WH1KXM5-BLK', color: 'Black', price_bdt: 35_000 },
      { sku: 'SNY-WH1KXM5-WHT', color: 'White', price_bdt: 35_000 },
    ],
  },
  {
    name: 'Nike Air Max 270',
    slug: 'nike-air-max-270',
    description: '<p>Nike Air Max 270 with Max Air unit for unmatched comfort. Lightweight mesh upper and durable rubber outsole.</p>',
    sku: 'NIK-AM270-BLK',
    price_bdt: 12_999,
    cost_price: 8_500,
    weight: 0.35,
    category_taxon: 'categories/sports/footwear',
    brand_taxon: 'brands/nike',
    tax_category: clothing_tax_category,
    shipping_category: default_shipping_category,
    variants: [
      { sku: 'NIK-AM270-BLK-42', color: 'Black', size: 'M', price_bdt: 12_999 },
      { sku: 'NIK-AM270-BLK-43', color: 'Black', size: 'L', price_bdt: 12_999 },
      { sku: 'NIK-AM270-WHT-42', color: 'White', size: 'M', price_bdt: 12_999 },
    ],
  },
  {
    name: 'Adidas Ultraboost 22',
    slug: 'adidas-ultraboost-22',
    description: '<p>Adidas Ultraboost 22 running shoes with responsive BOOST midsole and Primeknit+ upper. Designed for performance and style.</p>',
    sku: 'ADI-UB22-NVY',
    price_bdt: 14_500,
    cost_price: 9_500,
    weight: 0.32,
    category_taxon: 'categories/sports/footwear',
    brand_taxon: 'brands/adidas',
    tax_category: clothing_tax_category,
    shipping_category: default_shipping_category,
    variants: [
      { sku: 'ADI-UB22-NVY-42', color: 'Navy', size: 'M', price_bdt: 14_500 },
      { sku: 'ADI-UB22-BLK-42', color: 'Black', size: 'M', price_bdt: 14_500 },
    ],
  },
  {
    name: "Men's Cotton Polo Shirt",
    slug: 'mens-cotton-polo-shirt',
    description: '<p>Premium 100% cotton polo shirt. Breathable fabric, classic fit. Available in multiple colors and sizes.</p>',
    sku: 'FSH-MCPS',
    price_bdt: 1_299,
    cost_price: 550,
    weight: 0.2,
    category_taxon: 'categories/fashion/men',
    brand_taxon: nil,
    tax_category: clothing_tax_category,
    shipping_category: default_shipping_category,
    variants: [
      { sku: 'FSH-MCPS-BLK-M', color: 'Black', size: 'M', price_bdt: 1_299 },
      { sku: 'FSH-MCPS-BLK-L', color: 'Black', size: 'L', price_bdt: 1_299 },
      { sku: 'FSH-MCPS-BLU-M', color: 'Blue', size: 'M', price_bdt: 1_299 },
      { sku: 'FSH-MCPS-RED-M', color: 'Red', size: 'M', price_bdt: 1_299 },
    ],
  },
  {
    name: "Women's Casual Summer Dress",
    slug: 'womens-casual-summer-dress',
    description: '<p>Lightweight and comfortable summer dress. Perfect for casual outings. Available in various sizes.</p>',
    sku: 'FSH-WCSD',
    price_bdt: 1_899,
    cost_price: 750,
    weight: 0.15,
    category_taxon: 'categories/fashion/women',
    brand_taxon: nil,
    tax_category: clothing_tax_category,
    shipping_category: default_shipping_category,
    variants: [
      { sku: 'FSH-WCSD-WHT-S', color: 'White', size: 'S', price_bdt: 1_899 },
      { sku: 'FSH-WCSD-WHT-M', color: 'White', size: 'M', price_bdt: 1_899 },
      { sku: 'FSH-WCSD-BLU-S', color: 'Blue', size: 'S', price_bdt: 1_899 },
    ],
  },
  {
    name: 'Xiaomi Mi Smart Band 8',
    slug: 'xiaomi-mi-smart-band-8',
    description: '<p>Xiaomi Mi Smart Band 8 with 1.62" AMOLED display, 150+ workout modes, heart rate and SpO2 monitoring, and 16-day battery life.</p>',
    sku: 'XIA-MSB8-BLK',
    price_bdt: 3_999,
    cost_price: 2_800,
    weight: 0.03,
    category_taxon: 'categories/electronics/wearables',
    brand_taxon: 'brands/xiaomi',
    tax_category: electronics_tax_category,
    shipping_category: default_shipping_category,
    variants: [
      { sku: 'XIA-MSB8-BLK', color: 'Black', price_bdt: 3_999 },
      { sku: 'XIA-MSB8-WHT', color: 'White', price_bdt: 3_999 },
    ],
  },
  {
    name: "Walton 32\" LED TV (HD)",
    slug: 'walton-32-led-tv',
    description: '<p>Walton 32-inch HD LED TV with built-in digital tuner. HDMI/USB ports, slim design. Made in Bangladesh with 2-year warranty.</p>',
    sku: 'WLT-LTV32-HD',
    price_bdt: 16_999,
    cost_price: 13_000,
    weight: 5.0,
    category_taxon: 'categories/electronics/smartphones',
    brand_taxon: 'brands/walton',
    tax_category: electronics_tax_category,
    shipping_category: heavy_shipping_category,
    variants: [
      { sku: 'WLT-LTV32-HD-BLK', color: 'Black', price_bdt: 16_999 },
    ],
  },
  {
    name: "Men's Running Shoes - Lightweight",
    slug: 'mens-running-shoes-lightweight',
    description: '<p>Ultra-lightweight running shoes with responsive cushioning and breathable mesh. Ideal for daily runs and gym workouts.</p>',
    sku: 'FSH-MRSL',
    price_bdt: 2_499,
    cost_price: 1_200,
    weight: 0.28,
    category_taxon: 'categories/sports/footwear',
    brand_taxon: nil,
    tax_category: clothing_tax_category,
    shipping_category: default_shipping_category,
    variants: [
      { sku: 'FSH-MRSL-BLK-42', color: 'Black', size: 'M', price_bdt: 2_499 },
      { sku: 'FSH-MRSL-RED-42', color: 'Red', size: 'M', price_bdt: 2_499 },
      { sku: 'FSH-MRSL-BLU-43', color: 'Blue', size: 'L', price_bdt: 2_499 },
    ],
  },
]

products_data.each_with_index do |data, idx|
  product = Spree::Product.find_or_initialize_by(slug: data[:slug])
  if product.new_record?
    product.assign_attributes(
      name:               data[:name],
      description:        data[:description],
      available_on:       Time.current,
      status:             'active',
      shipping_category:  data[:shipping_category],
      tax_category:       data[:tax_category],
      slug:               data[:slug],
    )
    product.save!

    # Set price on master variant
    mv = product.master
    mv.set_price('BDT', data[:price_bdt])
  end

  # Option types (for products that use them)
  if data[:variants].any? { |v| v[:color] || v[:size] }
    option_types = []
    option_types << color_ot if data[:variants].any? { |v| v[:color] }
    option_types << size_ot if data[:variants].any? { |v| v[:size] }
    option_types.each do |ot|
      Spree::ProductOptionType.find_or_create_by!(product: product, option_type: ot)
    end
  end

  # Create variant(s)
  data[:variants].each do |var_data|
    master_variant = product.variants.first || product.master

    # Build option values hash
    ov_names = []
    ov_names << var_data[:color]&.downcase if var_data[:color]
    ov_names << var_data[:size] if var_data[:size]

    if master_variant.new_record?
      master_variant.assign_attributes(
        sku: var_data[:sku] || "#{product.slug}-#{SecureRandom.hex(4)}",
        cost_price: data[:cost_price],
        cost_currency: 'BDT',
        weight: data[:weight],
        weight_unit: 'kg',
        track_inventory: true,
      )
      master_variant.save!

      # Price
      master_variant.set_price('BDT', var_data[:price_bdt])

      # Option values
      ov_names.each do |ov_name|
        ov = Spree::OptionValue.find_by!(name: ov_name)
        Spree::VariantOptionValue.find_or_create_by!(
          variant: master_variant,
          option_value: ov,
        )
      end

      # Stock item
      Spree::StockItem.find_or_create_by!(
        variant: master_variant,
        stock_location: stock_location,
      ) { |si| si.count_on_hand = rand(10..50) }
    end
  end

  # Classifications (link to taxons)
  if data[:category_taxon]
    taxon = Spree::Taxon.find_by!(permalink: data[:category_taxon])
    Spree::Classification.find_or_create_by!(product: product, taxon: taxon)
  end
  if data[:brand_taxon]
    taxon = Spree::Taxon.find_by!(permalink: data[:brand_taxon])
    Spree::Classification.find_or_create_by!(product: product, taxon: taxon)
  end
end
puts "  ✓ Products (#{products_data.length} products with variants & stock)"

# ── 16. Sample customers ────────────────────────────────────────────────
customer_data = [
  { email: 'rahima.k@example.com', first_name: 'Rahima', last_name: 'Khatun', phone: '+880 1712-345678' },
  { email: 'ariful.islam@example.com', first_name: 'Ariful', last_name: 'Islam', phone: '+880 1812-345678' },
  { email: 'fatema.begum@example.com', first_name: 'Fatema', last_name: 'Begum', phone: '+880 1912-345678' },
  { email: 'kamrul.hasan@example.com', first_name: 'Kamrul', last_name: 'Hasan', phone: '+880 1612-345678' },
  { email: 'nusrat.jahan@example.com', first_name: 'Nusrat', last_name: 'Jahan', phone: '+880 1512-345678' },
]

customer_data.each do |cd|
  user = Spree::User.find_or_initialize_by(email: cd[:email])
  if user.new_record?
    user.password = 'password123'
    user.password_confirmation = 'password123'
    user.first_name = cd[:first_name]
    user.last_name = cd[:last_name]
    user.phone = cd[:phone]
    user.save!
  end
  user.spree_roles << user_role unless user.spree_roles.include?(user_role)
end
puts "  ✓ Sample customers (#{customer_data.length})"

# ── 17. Pathao Courier config ───────────────────────────────────────────
if defined?(Spree::PathaoCourierConfig)
  Spree::PathaoCourierConfig.find_or_create_by!(store: store) do |config|
    config.base_url = 'https://merchant-api-live.pathao.com'
    config.client_id = 'DEV_CLIENT_ID'
    config.client_secret = 'DEV_CLIENT_SECRET'
    config.username = 'dev@minimeshop.net'
    config.password = 'dev_password'
    config.sandbox = true
    config.pathao_store_id = 0
    config.default_delivery_type = 48
    config.default_item_type = 2
    config.default_weight = 0.5
  end
  puts "  ✓ Pathao Courier config (sandbox mode)"
end

# ── 18. CORS allowed origins ────────────────────────────────────────────
if defined?(Spree::AllowedOrigin)
  %w[
    http://localhost:3001
    http://localhost:3002
    http://localhost:5173
    http://localhost:5174
    https://minimeshop.net
    https://www.minimeshop.net
    https://storefront.minimeshop.net
  ].each do |origin|
    Spree::AllowedOrigin.find_or_create_by!(origin: origin, store: store)
  end
  puts "  ✓ CORS allowed origins"
end

puts ""
puts "✅ Seed complete!"
puts "   Admin:    admin@minimeshop.net / password123"
puts "   Store:    MiniMeShop (minimeshop.net) — BDT"
puts "   Products: #{Spree::Product.count} products, #{Spree::Variant.count} variants"
puts "   Users:    #{Spree::User.count} customers"
