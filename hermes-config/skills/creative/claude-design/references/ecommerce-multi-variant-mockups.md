# E-Commerce Multi-Variant Mockup Pattern

## When to Use

When the user provides a website proposal (usually PDF) and asks for design mockups for multiple industry themes. Common for "limited product store" or "toko online" projects with a Versi A (simpel + WA order) budget.

## Workflow

### 1. Extract the Proposal

PDF files are binary — `read_file` returns garbage. Use `pdftotext`:

```bash
# Quick preview
pdftotext /path/to/proposal.pdf - | head -200

# Full extraction to temp file
pdftotext /path/to/proposal.pdf /tmp/proposal.txt
read_file(path="/tmp/proposal.txt")
```

If `pdftotext` missing: `apt-get install -y poppler-utils`

### 2. Identify Scope

From the proposal, extract:
- **Fitur core** yang harus ada (usually: hero, katalog, kategori, detail produk, titip jual, about)
- **Fitur opsional** (payment gateway, CMS, wishlist — exclude for Versi A)
- **Pilihan versi** dan harga (Versi A = paling murah, biasanya simpel + WA order)

### 3. Generate Mockups (One HTML Per Theme)

Each mockup is a **self-contained HTML file** using:
- Tailwind CSS (CDN)
- Font Awesome 6.5 (CDN)
- Google Fonts for typography

File naming: `mockup-<tema>.html`

### 4. Theme Differentiation

Each theme MUST feel distinctly different. See the comparison table below.

| Element | Industrial/Tools | Fashion/Streetwear | Tech/Gadget |
|---------|-----------------|-------------------|-------------|
| **Primary** | Orange `#f97316` | Black `#000000` | Blue `#3b82f6` |
| **Display Font** | Inter Black | Bebas Neue | Space Grotesk |
| **Product Card** | Spec-heavy, brand badge | Image-heavy 3:4, hover overlay | Clean, spec tags |
| **Hero** | Gradient dark + pattern | Full image overlay | Gradient blue + grid |
| **Mood** | Bold, functional | Exclusive, editorial | Modern, clean |

### 5. Consistent Page Structure

Navbar → Hero Banner → Kategori → Katalog Produk → Form Titip Jual → About → Footer → Floating WA Button

### 6. Content Guidelines

**Do:** Realistic Indonesian product names & prices, Font Awesome icons as image placeholders, Indonesian copy, functional WA buttons.

**Don't:** Lorem Ipsum, same card style across variants, generic SaaS layouts, forget mobile responsiveness, actual stock photos.

### 7. Generate DESIGN.md

Document all variants with color palettes, typography, component descriptions, comparison table, responsive breakpoints, and developer handoff notes.
