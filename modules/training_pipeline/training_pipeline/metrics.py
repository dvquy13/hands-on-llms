import numpy as np


def compute_perplexity(predictions: np.ndarray) -> float:
    """
    Compute perplexity metric.
    --- Interpretation (not from original author)
    This computation of perplexity calculates average probability of the words/tokens for the label texts.
    Rationale is that the higher the prob that LLM assigns to label texts the better it can generate real-world texts.
    ---

    Parameters:
    predictions (np.ndarray): Array of predicted values.

    Returns:
    float: Perplexity metric value.
    """

    return np.exp(predictions.mean()).item()
