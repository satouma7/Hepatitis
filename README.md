# Deep Learning-based Differentiation of Drug-induced Liver Injury and Autoimmune Hepatitis: A Pathological and Computational Approach

This repository contains the source code used in the study:

**“Deep Learning-based Differentiation of Drug-induced Liver Injury and Autoimmune Hepatitis: A Pathological and Computational Approach”**

The code supports image preprocessing, deep learning–based classification, explainable AI analysis, and dimensionality reduction of pathological image data.


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
- Test scripts
- Model architecture definitions
- Performance evaluation outputs

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

## Notes
- This repository is provided for research and reproducibility purposes.
- The code corresponds to the version used in the submitted manuscript; future updates may refine structure or documentation.

## Contact
For questions regarding the code or the study, please contact the corresponding author.
