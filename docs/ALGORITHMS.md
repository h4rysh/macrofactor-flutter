# Adherence-Neutral Algorithmic Specifications

## 1. Weight Trend V2 (`lib/domain/algorithms/weight_trend_v2.dart`)

### The Problem with Raw Scale Weight
Daily scale weight reflects acute fluid shifts (sodium intake, carbohydrate glycogen binding at $3\text{g } \text{H}_2\text{O} / \text{g glycogen}$, cortisol, intestinal transit time), creating up to $\pm 2.5\text{ kg}$ of daily noise. Naive smoothing (such as standard moving averages) introduces phase lag, delaying critical coaching adjustments.

### Algorithmic Pipeline
1. **Dynamic Interval Scaling ($\Delta t$)**:
   $$\alpha(\Delta t) = 1 - (1 - \alpha_0)^{\Delta t}$$
   Where $\alpha_0 = 0.10$ corresponds to a nominal half-life of $\approx 6.5$ days.

2. **Causal Forward Pass**:
   $$EMA_t^{\text{fwd}} = \alpha \cdot w_t + (1 - \alpha) \cdot EMA_{t-1}^{\text{fwd}}$$

3. **Zero-Phase Backward Pass**:
   To eliminate phase distortion when reviewing historical logs:
   $$EMA_t^{\text{bwd}} = \alpha \cdot w_t + (1 - \alpha) \cdot EMA_{t+1}^{\text{bwd}}$$
   $$\text{Trend}_t = \frac{1}{2} \left( EMA_t^{\text{fwd}} + EMA_t^{\text{bwd}} \right)$$

4. **Biological Noise Envelope (Median Absolute Deviation)**:
   $$\text{Residual}_t = |w_t - \text{Trend}_t|$$
   $$\text{MAD}_t = \text{median}(\text{Residual}_{t-k \dots t})$$
   $$\text{Upper Bound}_t = \text{Trend}_t + 2.5 \cdot \text{MAD}_t$$
   $$\text{Lower Bound}_t = \text{Trend}_t - 2.5 \cdot \text{MAD}_t$$

---

## 2. Dynamic Expenditure Algorithm V3 (`lib/domain/algorithms/expenditure_algorithm_v3.dart`)

### Thermodynamic Energy Balance Model
The human body obeys the First Law of Thermodynamics:
$$\text{Rate of Tissue Change} = \text{Energy Intake} - \text{Total Daily Energy Expenditure (TDEE)}$$

Assuming tissue energy density $\kappa = 7700\text{ kcal/kg}$, an observed change in trend weight $\Delta w_k$ over interval $\Delta t$ days yields an empirical expenditure observation:
$$z_k = C_k - \kappa \cdot \frac{\Delta w_k}{\Delta t}$$

### 1D Bayesian Kalman Filter Formulation

#### 1. State Prediction
$$\hat{x}_{k|k-1} = \hat{x}_{k-1}$$
$$P_{k|k-1} = P_{k-1} + Q_k$$
Where $Q_k$ is the process noise variance representing metabolic adaptation ($\approx 1500\text{ kcal}^2/\text{day}$).

#### 2. Measurement Variance Adaptation ($R_k$)
Measurement noise is scaled dynamically based on weight variance $\sigma_{\Delta w}^2$ and logging regularity:
$$R_k = R_{\text{base}} \cdot \left(1 + \frac{\sigma_{\Delta w}^2}{\sigma_0^2}\right) \cdot (1 + \Delta t_{\text{gap}})$$
If the user's scale weight fluctuated wildly, $R_k$ increases, causing the Kalman gain to drop and preventing the expenditure from over-reacting.

#### 3. Kalman Gain Computation
$$K_k = \frac{P_{k|k-1}}{P_{k|k-1} + R_k}$$

#### 4. Posterior State & Covariance Update
$$\hat{x}_k^{\text{raw}} = \hat{x}_{k|k-1} + K_k (z_k - \hat{x}_{k|k-1})$$
$$P_k = (1 - K_k) P_{k|k-1}$$

#### 5. Daily Flux Clamping
To prevent sudden spikes in caloric recommendations:
$$\Delta x_k = \text{clamp}\left(\hat{x}_k^{\text{raw}} - \hat{x}_{k-1}, -150\text{ kcal}, +150\text{ kcal}\right)$$
$$\hat{x}_k = \hat{x}_{k-1} + \Delta x_k$$
