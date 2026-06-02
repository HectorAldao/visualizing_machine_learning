use godot::prelude::*;
use ratex_layout::{layout, to_display_list, LayoutOptions};
use ratex_svg::{render_to_svg, SvgOptions};
use ratex_types::{Color, MathStyle};
use std::panic::{catch_unwind, AssertUnwindSafe};

const WHITE: &str = "#FFFFFF";

#[derive(GodotClass)]
#[class(base = RefCounted)]
struct LatexSvgGenerator {
    base: Base<RefCounted>,
}

#[godot_api]
impl IRefCounted for LatexSvgGenerator {
    fn init(base: Base<RefCounted>) -> Self {
        Self { base }
    }
}

#[godot_api]
impl LatexSvgGenerator {
    #[func]
    fn render_svg(&self, latex: GString, font_size: f64, padding: f64) -> GString {
        let latex = latex.to_string();
        let result = catch_unwind(AssertUnwindSafe(|| {
            render_svg_internal(&latex, font_size, padding)
        }));

        match result {
            Ok(Ok(svg)) => GString::from(svg.as_str()),
            Ok(Err(err)) => {
                godot_error!("LatexSvgGenerator: {err}");
                GString::from("")
            }
            Err(_) => {
                godot_error!("LatexSvgGenerator: RaTeX panicked while rendering formula");
                GString::from("")
            }
        }
    }
}

fn render_svg_internal(latex: &str, font_size: f64, padding: f64) -> Result<String, String> {
    ensure_embedded_katex_fonts()?;

    if latex.trim().is_empty() {
        return Ok(empty_svg());
    }

    let nodes = ratex_parser::parse(latex).map_err(|err| format!("parse failed: {err}"))?;
    let layout_options = LayoutOptions::default()
        .with_style(MathStyle::Display)
        .with_color(Color::WHITE);
    let root = layout(&nodes, &layout_options);
    let display_list = to_display_list(&root);

    let svg_options = SvgOptions {
        font_size: font_size.clamp(0.0, 256.0),
        padding: padding.clamp(0.0, 128.0),
        stroke_width: 1.5,
        embed_glyphs: true,
        font_dir: String::new(),
    };

    let svg = render_to_svg(&display_list, &svg_options);
    normalize_for_thorvg(&svg)
}

fn ensure_embedded_katex_fonts() -> Result<(), String> {
    if ratex_katex_fonts::ttf_bytes("KaTeX_Main-Regular.ttf").is_some() {
        Ok(())
    } else {
        Err("embedded KaTeX fonts are unavailable; build ratex-svg with embed-fonts".to_string())
    }
}

fn empty_svg() -> String {
    format!(
        r#"<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1 1" width="1" height="1"><path d="M0 0Z" fill="{WHITE}"/></svg>"#
    )
}

fn normalize_for_thorvg(svg: &str) -> Result<String, String> {
    let mut out = String::with_capacity(svg.len());
    let mut index = 0usize;

    while let Some(relative_start) = svg[index..].find('<') {
        let start = index + relative_start;
        out.push_str(&svg[index..start]);

        let Some(relative_end) = svg[start..].find('>') else {
            return Err("malformed SVG tag".to_string());
        };
        let end = start + relative_end;
        let tag = &svg[start..=end];

        if tag.starts_with("<text") {
            return Err(
                "RaTeX emitted a <text> tag; embed_glyphs did not produce paths".to_string(),
            );
        }
        if tag.starts_with("<image") {
            return Err(
                "RaTeX emitted a raster <image>; this renderer only accepts path SVG".to_string(),
            );
        }

        if tag.starts_with("<svg ") {
            out.push_str(&strip_pt_length_units(tag));
        } else if tag.starts_with("<rect ") {
            out.push_str(&rect_tag_to_path(tag)?);
        } else if tag.starts_with("<line ") {
            out.push_str(&line_tag_to_paths(tag)?);
        } else {
            out.push_str(tag);
        }

        index = end + 1;
    }

    out.push_str(&svg[index..]);
    Ok(force_white_paint(&out))
}

fn strip_pt_length_units(tag: &str) -> String {
    let tag = strip_pt_length_attr(tag, "width");
    strip_pt_length_attr(&tag, "height")
}

fn strip_pt_length_attr(tag: &str, name: &str) -> String {
    let needle = format!(r#"{name}=""#);
    let Some(value_start) = tag.find(&needle).map(|start| start + needle.len()) else {
        return tag.to_string();
    };
    let Some(relative_end) = tag[value_start..].find('"') else {
        return tag.to_string();
    };

    let value_end = value_start + relative_end;
    let value = &tag[value_start..value_end];
    let Some(number) = value.strip_suffix("pt") else {
        return tag.to_string();
    };

    format!("{}{}{}", &tag[..value_start], number, &tag[value_end..])
}

fn rect_tag_to_path(tag: &str) -> Result<String, String> {
    let x = parse_attr_f64(tag, "x")?.unwrap_or(0.0);
    let y = parse_attr_f64(tag, "y")?.unwrap_or(0.0);
    let width = parse_attr_f64(tag, "width")?.unwrap_or(0.0);
    let height = parse_attr_f64(tag, "height")?.unwrap_or(0.0);
    Ok(rect_path(x, y, width, height))
}

fn line_tag_to_paths(tag: &str) -> Result<String, String> {
    let x1 = parse_attr_f64(tag, "x1")?.unwrap_or(0.0);
    let y1 = parse_attr_f64(tag, "y1")?.unwrap_or(0.0);
    let x2 = parse_attr_f64(tag, "x2")?.unwrap_or(x1);
    let y2 = parse_attr_f64(tag, "y2")?.unwrap_or(y1);
    let stroke_width = parse_attr_f64(tag, "stroke-width")?
        .unwrap_or(1.0)
        .max(1e-6);

    if (y1 - y2).abs() > f64::EPSILON {
        return Ok(format!(
            r#"<path d="M{} {} L{} {}" fill="none" stroke="{WHITE}" stroke-width="{}" stroke-linecap="round"/>"#,
            fmt_num(x1),
            fmt_num(y1),
            fmt_num(x2),
            fmt_num(y2),
            fmt_num(stroke_width)
        ));
    }

    let start = x1.min(x2);
    let end = x1.max(x2);
    let y = y1 - stroke_width / 2.0;

    let Some(dasharray) = attr(tag, "stroke-dasharray") else {
        return Ok(rect_path(start, y, end - start, stroke_width));
    };

    let dash = dasharray
        .split(|ch: char| ch.is_whitespace() || ch == ',')
        .find_map(|part| part.parse::<f64>().ok())
        .unwrap_or(stroke_width * 3.0)
        .max(1e-6);
    let gap = dash;
    let mut cursor = start;
    let mut out = String::new();

    while cursor < end {
        let segment_end = (cursor + dash).min(end);
        out.push_str(&rect_path(cursor, y, segment_end - cursor, stroke_width));
        cursor += dash + gap;
    }

    Ok(out)
}

fn rect_path(x: f64, y: f64, width: f64, height: f64) -> String {
    if width <= 0.0 || height <= 0.0 {
        return String::new();
    }

    let x2 = x + width;
    let y2 = y + height;
    format!(
        r#"<path d="M{} {} L{} {} L{} {} L{} {} Z" fill="{WHITE}" fill-rule="nonzero" stroke="none"/>"#,
        fmt_num(x),
        fmt_num(y),
        fmt_num(x2),
        fmt_num(y),
        fmt_num(x2),
        fmt_num(y2),
        fmt_num(x),
        fmt_num(y2)
    )
}

fn parse_attr_f64(tag: &str, name: &str) -> Result<Option<f64>, String> {
    let Some(value) = attr(tag, name) else {
        return Ok(None);
    };
    value
        .parse::<f64>()
        .map(Some)
        .map_err(|_| format!("invalid SVG numeric attribute {name}={value}"))
}

fn attr<'a>(tag: &'a str, name: &str) -> Option<&'a str> {
    let needle = format!("{name}=\"");
    let start = tag.find(&needle)? + needle.len();
    let end = tag[start..].find('"')? + start;
    Some(&tag[start..end])
}

fn force_white_paint(svg: &str) -> String {
    let mut out = String::with_capacity(svg.len());
    let mut index = 0usize;

    while let Some((position, needle)) = next_paint_attr(svg, index) {
        out.push_str(&svg[index..position + needle.len()]);
        let value_start = position + needle.len();

        let Some(relative_end) = svg[value_start..].find('"') else {
            index = value_start;
            break;
        };

        let value_end = value_start + relative_end;
        let value = &svg[value_start..value_end];
        if value == "none" {
            out.push_str(value);
        } else {
            out.push_str(WHITE);
        }
        index = value_end;
    }

    out.push_str(&svg[index..]);
    out
}

fn next_paint_attr(svg: &str, offset: usize) -> Option<(usize, &'static str)> {
    let fill = svg[offset..]
        .find("fill=\"")
        .map(|pos| (offset + pos, "fill=\""));
    let stroke = svg[offset..]
        .find("stroke=\"")
        .map(|pos| (offset + pos, "stroke=\""));

    match (fill, stroke) {
        (Some(fill), Some(stroke)) => Some(if fill.0 <= stroke.0 { fill } else { stroke }),
        (Some(fill), None) => Some(fill),
        (None, Some(stroke)) => Some(stroke),
        (None, None) => None,
    }
}

fn fmt_num(n: f64) -> String {
    let s = format!("{n:.6}");
    let s = s.trim_end_matches('0');
    let s = s.trim_end_matches('.');
    if s.is_empty() || s == "-" {
        "0".to_string()
    } else {
        s.to_string()
    }
}

struct LatexRendererExtension;

#[gdextension]
unsafe impl ExtensionLibrary for LatexRendererExtension {}
