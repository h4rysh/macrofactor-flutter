# Sique Algorithmic Specifications & Mathematical Foundations

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

## 2. Joint-State Kalman Expenditure Filter V4 (`lib/domain/algorithms/expenditure_kalman_v4.dart`)

### State-Space Formulation
Sique models human metabolic adaptation using a 2D joint state vector combining true underlying weight $W_t$ (kg) and daily metabolic expenditure $E_t$ (kcal/day):
$$x_t = \begin{bmatrix} W_t \\ E_t \end{bmatrix}$$

### Thermodynamic Process Transition
$$\begin{bmatrix} W_{t+1} \\ E_{t+1} \end{bmatrix} = \begin{bmatrix} 1 & -\frac{\Delta t}{7700} \\ 0 & 1 \end{bmatrix} \begin{bmatrix} W_t \\ E_t \end{bmatrix} + \begin{bmatrix} \frac{\Delta t \cdot I_t}{7700} \\ 0 \end{bmatrix} + w_t$$
Where:
- $I_t$ is caloric energy intake (kcal/day)
- $7700\text{ kcal/kg}$ represents the human tissue energy density constant
- Process covariance $Q$:
  $$Q = \begin{bmatrix} Q_W & 0 \\ 0 & Q_E \end{bmatrix} = \begin{bmatrix} 0.04^2 & 0 \\ 0 & 10^2 \end{bmatrix}$$

### Measurement Model & Huber-Clipped Innovation
When scale weight $z_t$ is observed:
$$y_t = z_t - H x_{t|t-1}, \quad H = [1 \quad 0]$$
$$S_t = H P_{t|t-1} H^T + R, \quad R = 0.6^2\text{ kg}^2$$
To reject biological fluid spikes (e.g. sodium or water retention), innovation $y_t$ is robustly Huber-clipped at $3\sigma = 3\sqrt{S_t}$:
$$\tilde{y}_t = \text{clamp}(y_t, -3\sqrt{S_t}, 3\sqrt{S_t})$$

### Unlogged Day Handling & Regularity Guard
- When a day lacks food logging, caloric intake is imputed using the 14-day rolling mean intake $\bar{I}_{14}$.
- Process noise on weight is augmented during unlogged days by $((0.15 \times \bar{I}_{14})/7700)^2$.
- If more than 3 of the last 7 days are unlogged, metabolic updates are automatically paused until logging resumes.

---

## 3. Coaching Engine & 7-Day Energy Conservation (`lib/domain/algorithms/coaching_engine.dart`)

### Daily Energy Deficit / Surplus
$$\Delta \text{Energy} = -\text{currentWeightKg} \times \left(\frac{|\text{weeklyRatePct}|}{100}\right) \times \frac{7700}{7} = -\text{weeklyKgDelta} \times 1100\text{ kcal}$$

### Strict Weekly Calorie Conservation
$$\sum_{d=1}^{7} \text{Calories}_d = 7 \times \text{DailyAverageCalories}$$
- On shifted workout days, workout days receive $+9\%$ energy ($\approx 150 - 300\text{ kcal}$), balanced across rest days.
- Every day strictly respects the user's physiological `calorieFloor`.
