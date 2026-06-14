from __future__ import annotations

from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np


OUTPUT_DIR = Path(__file__).resolve().parent / "plots"
X_MIN = -6.0
X_MAX = 6.0
NUM_POINTS = 800
FOREGROUND_COLOR = "#ffffff"
GRID_COLOR = "#ffffff"


def sigmoid(x: np.ndarray) -> np.ndarray:
    return 1.0 / (1.0 + np.exp(-x))


def relu(x: np.ndarray) -> np.ndarray:
    return np.maximum(0.0, x)


def linear(x: np.ndarray) -> np.ndarray:
    return x


def softmax_selected_class(selected_logit: np.ndarray, num_classes: int) -> np.ndarray:
    """Softmax probability for one class, with the other logits fixed at 0.

    This keeps Softmax plottable in 2D: x is the logit of the selected class,
    and the output is its probability among `num_classes` classes.
    """

    exp_selected = np.exp(selected_logit)
    return exp_selected / (exp_selected + num_classes - 1)


def configure_axes(ax: plt.Axes, title: str, xlabel: str, ylabel: str) -> None:
    ax.axhline(0, color=FOREGROUND_COLOR, linewidth=0.8)
    ax.axvline(0, color=FOREGROUND_COLOR, linewidth=0.8)
    ax.grid(True, color=GRID_COLOR, alpha=0.25, linewidth=0.8)
    ax.set_title(title)
    ax.set_xlabel(xlabel)
    ax.set_ylabel(ylabel)
    ax.tick_params(colors=FOREGROUND_COLOR)
    ax.title.set_color(FOREGROUND_COLOR)
    ax.xaxis.label.set_color(FOREGROUND_COLOR)
    ax.yaxis.label.set_color(FOREGROUND_COLOR)

    for spine in ax.spines.values():
        spine.set_color(FOREGROUND_COLOR)


def save_plot(
    filename: str,
    title: str,
    x: np.ndarray,
    y: np.ndarray,
    xlabel: str = "Entrada ponderada z",
    ylabel: str = "Salida",
    y_limits: tuple[float, float] | None = None,
) -> None:
    fig, ax = plt.subplots(figsize=(8, 5), dpi=160)
    ax.plot(x, y, color="#2563eb", linewidth=3)
    configure_axes(ax, title, xlabel, ylabel)

    if y_limits is not None:
        ax.set_ylim(*y_limits)

    fig.tight_layout()
    fig.savefig(OUTPUT_DIR / filename, transparent=True)
    plt.close(fig)


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    x = np.linspace(X_MIN, X_MAX, NUM_POINTS)

    save_plot(
        "sigmoide.png",
        "Función sigmoide",
        x,
        sigmoid(x),
        y_limits=(-0.05, 1.05),
    )
    save_plot("lineal.png", "Función lineal", x, linear(x))
    save_plot("relu.png", "Función ReLU", x, relu(x), y_limits=(-0.5, X_MAX + 0.5))
    for num_classes in range(2, 7):
        save_plot(
            f"softmax_{num_classes}clases.png",
            f"Softmax para {num_classes} clases",
            x,
            softmax_selected_class(x, num_classes),
            xlabel="Logit de la clase elegida, con el resto en 0",
            ylabel="Probabilidad de la clase",
            y_limits=(-0.05, 1.05),
        )

    print(f"Plots guardados en: {OUTPUT_DIR}")


if __name__ == "__main__":
    main()
