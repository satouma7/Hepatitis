# Anisotropic Cellular Forces Drive Hexagonal-to-Tetragonal Tiling Transitions in the *Drosophila* Eye

This repository contains the source code used in the study:

**“Anisotropic Cellular Forces Drive Hexagonal-to-Tetragonal Tiling Transitions in the *Drosophila* Eye”**

The code supports image preprocessing, deep learning–based classification, explainable AI analysis, and dimensionality reduction of cellular morphology data derived from *Drosophila* eye tissues.


## Repository Structure

The repository is organized into the following four main folders, corresponding to the analytical pipeline described in the paper.

### 1. `Preprocessing/`
Image preprocessing scripts used to prepare microscopy images for downstream analysis.

Typical steps include:
- Cropping and resizing
- Background removal
- Format conversion

### 2. `CNN/`
Convolutional Neural Network (CNN) implementation for classification tasks.

This folder includes:
- Training scripts
- Test / evaluation scripts
- Model architecture definitions
- Performance evaluation outputs (e.g., accuracy, confusion matrices)

### 3. `GradCAM_GuidedBP/`
Explainable AI analyses for visualizing CNN decision-making.

This folder contains code for:
- Grad-CAM
- Guided Backpropagation
- Overlay visualization on original images

### 4. `Dimension/`
Dimensionality reduction and feature-space analysis.

Includes scripts for:
- PCA
- UMAP
- t-SNE

## Requirements
- MATLAB (with Deep Learning Toolbox)
- Python (if applicable to specific scripts)
- Standard scientific Python libraries (NumPy, SciPy, scikit-learn, etc.)

Details may vary depending on the specific analysis step.


## Notes
- This repository is provided for research and reproducibility purposes.
- The code corresponds to the version used in the submitted manuscript; future updates may refine structure or documentation.


## Contact
For questions regarding the code or the study, please contact the corresponding author.
