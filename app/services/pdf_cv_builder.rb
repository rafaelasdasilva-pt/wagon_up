class PdfCvBuilder
  # Brand colours
  BRAND      = "5B4EE8"
  BRAND_DARK = "3D32C4"
  INK        = "1A1A2E"
  INK_3      = "6B7280"
  BORDER     = "E5E7EB"
  WHITE      = "FFFFFF"
  LIGHT_BG   = "F5F3FF"

  def initialize(cv_data, role)
    @cv   = cv_data
    @role = role
  end

  def build
    pdf = ::Prawn::Document.new(
      page_size:   "A4",
      margin:      [ 0, 0, 0, 0 ]
    )

    pdf.font_families.update(
      "Helvetica" => {
        normal:      "Helvetica",
        bold:        "Helvetica-Bold",
        italic:      "Helvetica-Oblique",
        bold_italic: "Helvetica-BoldOblique"
      }
    )
    pdf.font "Helvetica"

    page_w = pdf.bounds.width  # 595.28

    draw_header(pdf, page_w)
    draw_body(pdf, page_w)

    pdf.render
  end

  private

  # ── Header ────────────────────────────────────────────────────────────────
  def draw_header(pdf, page_w)
    header_h = 130
    pdf.bounding_box([ 0, pdf.cursor ], width: page_w, height: header_h) do
      pdf.fill_color BRAND
      pdf.fill_rectangle([ 0, header_h ], page_w, header_h)

      # Name
      pdf.fill_color WHITE
      pdf.bounding_box([ 36, header_h - 24 ], width: page_w - 72) do
        pdf.text safe(@cv["name"]), size: 22, style: :bold, color: WHITE
        pdf.move_down 6
        pdf.text safe(@cv["headline"]), size: 11, color: "D4CFFF"
        pdf.move_down 10

        # Contact row
        contact_parts = []
        contact_parts << @cv["email"]    if @cv["email"].present?
        contact_parts << @cv["phone"]    if @cv["phone"].present?
        contact_parts << @cv["linkedin"] if @cv["linkedin"].present?
        contact_parts << @cv["location"] if @cv["location"].present?

        unless contact_parts.empty?
          pdf.text contact_parts.map { |p| safe(p) }.join("   |   "), size: 8.5, color: "C4BFFF"
        end
      end
    end
    pdf.move_down 0
  end

  # ── Body ──────────────────────────────────────────────────────────────────
  def draw_body(pdf, page_w)
    left_col_w  = 175
    right_col_w = page_w - left_col_w - 1
    body_top    = pdf.cursor
    margin      = 36

    # We draw both columns independently and track heights
    left_content  = build_left_column(pdf, left_col_w - margin, margin)
    right_content = build_right_column(pdf, right_col_w - margin * 2, margin)

    # Left column background
    pdf.save_graphics_state do
      pdf.fill_color LIGHT_BG
      pdf.fill_rectangle([ 0, body_top ], left_col_w, pdf.bounds.absolute_bottom - body_top + 800)
    end

    # Draw left column
    pdf.bounding_box([ margin, body_top ], width: left_col_w - margin) do
      left_content.call(pdf)
    end

    # Draw right column
    pdf.bounding_box([ left_col_w + margin, body_top ], width: right_col_w - margin * 2) do
      right_content.call(pdf)
    end
  end

  def build_left_column(pdf, width, margin)
    -> (pdf) {
      pdf.move_down 24

      # Skills – Technical
      if @cv.dig("skills", "technical").present?
        section_label(pdf, "Technical Skills")
        @cv["skills"]["technical"].each do |skill|
          skill_tag(pdf, skill)
        end
        pdf.move_down 12
      end

      # Skills – Soft
      if @cv.dig("skills", "soft").present?
        section_label(pdf, "Soft Skills")
        @cv["skills"]["soft"].each do |skill|
          skill_tag(pdf, skill)
        end
        pdf.move_down 12
      end

      # Education
      if @cv["education"].present?
        section_label(pdf, "Education")
        @cv["education"].each do |edu|
          pdf.move_down 6
          pdf.text safe(edu["degree"]), size: 9, style: :bold, color: INK
          pdf.text safe(edu["institution"]), size: 8.5, color: BRAND
          pdf.text safe(edu["year"]), size: 8, color: INK_3
          Array(edu["highlights"]).each do |h|
            pdf.move_down 2
            pdf.text "- #{safe(h)}", size: 8, color: INK_3, indent_paragraphs: 6
          end
        end
        pdf.move_down 12
      end
    }
  end

  def build_right_column(pdf, width, margin)
    -> (pdf) {
      pdf.move_down 24

      # Summary
      if @cv["summary"].present?
        section_label(pdf, "Professional Summary")
        pdf.move_down 4
        pdf.text safe(@cv["summary"]), size: 9.5, color: INK, leading: 4
        pdf.move_down 14
      end

      # Experience
      if @cv["experience"].present?
        section_label(pdf, "Experience")
        @cv["experience"].each_with_index do |exp, i|
          pdf.move_down(i == 0 ? 6 : 10)
          pdf.text safe(exp["title"]), size: 10, style: :bold, color: INK
          company_line = [ exp["company"], exp["period"] ].select(&:present?).map { |s| safe(s) }.join("  |  ")
          pdf.text safe(company_line), size: 8.5, color: BRAND
          pdf.move_down 3
          Array(exp["highlights"]).each do |h|
            pdf.text "- #{safe(h)}", size: 9, color: INK, indent_paragraphs: 10, leading: 2
            pdf.move_down 2
          end
        end
        pdf.move_down 14
      end

      # Projects
      if @cv["projects"].present?
        section_label(pdf, "Projects")
        @cv["projects"].each_with_index do |proj, i|
          pdf.move_down(i == 0 ? 6 : 10)
          pdf.text safe(proj["name"]), size: 10, style: :bold, color: INK
          pdf.text safe(proj["description"]), size: 9, color: INK_3, leading: 3
          if Array(proj["tech"]).present?
            pdf.move_down 2
            pdf.text Array(proj["tech"]).map { |t| safe(t) }.join(" | "), size: 8, color: BRAND
          end
        end
      end
    }
  end

  # ── Helpers ───────────────────────────────────────────────────────────────
  def section_label(pdf, text)
    pdf.fill_color BRAND
    pdf.text text.upcase, size: 7.5, style: :bold, color: BRAND, character_spacing: 1.2
    pdf.stroke_color BRAND
    pdf.stroke_horizontal_rule
    pdf.fill_color INK
    pdf.move_down 2
  end

  def skill_tag(pdf, text)
    pdf.move_down 3
    pdf.text "> #{safe(text)}", size: 8.5, color: INK
  end

  def safe(str)
    text = str.to_s.encode("UTF-8", invalid: :replace, undef: :replace, replace: "?")
    ActiveSupport::Inflector.transliterate(text)
  end
end
