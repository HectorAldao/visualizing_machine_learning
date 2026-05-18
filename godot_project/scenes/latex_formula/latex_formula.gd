class_name LatexFormula
extends "res://addons/latex_renderer/latex_renderer.gd"


static func newone(latex_text: String, color: Color = Color.WHITE) -> LatexFormula:
	var new_latexformula: LatexFormula = preload(Constants.SCENES.latex_formula).instantiate()
	new_latexformula.formula = latex_text
	new_latexformula.formula_color = color
	return new_latexformula
