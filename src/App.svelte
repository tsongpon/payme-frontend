<script>
  // State variables
  let target = '';
  let displayValue = '0';
  let calculationHistory = '';
  let currentValue = '0';
  let operator = null;
  let waitingForOperand = false;
  let isLoading = false;
  let qrCodeSrc = null;
  let error = null;
  let isButtonDisabled = true;
  let isTargerEntered = false;

  // Backend service URL
  const BACKEND_URL = "https://fnxuhngnew.ap-southeast-1.awsapprunner.com/qrcode";

  // Validation functions
  function isValidThaiIdOrPhone(value) {
    // Thai citizen ID: 13 digits
    const thaiIdPattern = /^\d{13}$/;
    
    // Thai mobile phone: 10 digits starting with 0
    const thaiPhonePattern = /^0\d{9}$/;
    
    return thaiIdPattern.test(value) || thaiPhonePattern.test(value);
  }

  function isValidAmount(value) {
    // Number with exactly 2 decimal places or a whole number
    return value !== '0' && parseFloat(value) > 0;
  }

  // Format amount to always have 2 decimal places
  function formatAmount(value) {
    const num = parseFloat(value);
    return num.toFixed(2);
  }

  // Calculator functions
  function inputDigit(digit) {
    if (waitingForOperand) {
      displayValue = String(digit);
      waitingForOperand = false;
    } else {
      displayValue = displayValue === '0' ? String(digit) : displayValue + digit;
    }
    updateButtonState();
  }

  function inputDecimal() {
    if (waitingForOperand) {
      displayValue = '0.';
      waitingForOperand = false;
    } else if (displayValue.indexOf('.') === -1) {
      displayValue = displayValue + '.';
    }
    updateButtonState();
  }

  function clearDisplay() {
    displayValue = '0';
    currentValue = '0';
    operator = null;
    waitingForOperand = false;
    calculationHistory = '';
    updateButtonState();
  }

  function handleOperator(nextOperator) {
    const inputValue = parseFloat(displayValue);
    
    if (operator && waitingForOperand) {
      operator = nextOperator;
      calculationHistory = calculationHistory.slice(0, -1) + nextOperator;
      return;
    }
    
    if (currentValue === '0') {
      currentValue = String(inputValue);
    } else {
      const result = performCalculation();
      currentValue = String(result);
      displayValue = String(result);
    }
    
    waitingForOperand = true;
    operator = nextOperator;
    
    calculationHistory = currentValue + ' ' + nextOperator + ' ';
    updateButtonState();
  }

  function performCalculation() {
    const inputValue = parseFloat(displayValue);
    const previousValue = parseFloat(currentValue);
    
    let result;
    switch (operator) {
      case '+':
        result = previousValue + inputValue;
        break;
      case '-':
        result = previousValue - inputValue;
        break;
      case '*':
        result = previousValue * inputValue;
        break;
      case '/':
        result = previousValue / inputValue;
        break;
      default:
        return inputValue;
    }
    
    return Math.round(result * 100) / 100; // Round to 2 decimal places
  }

  function handleEquals() {
    const inputValue = parseFloat(displayValue);
    
    if (operator) {
      calculationHistory += displayValue + ' = ';
      const result = performCalculation();
      displayValue = String(result);
      currentValue = '0';
      operator = null;
      waitingForOperand = true;
      updateButtonState();
    }
  }

  function updateButtonState() {
    isButtonDisabled = !isValidThaiIdOrPhone(target) || !isValidAmount(displayValue) || isLoading;
  }

  // Handle form submission
  async function handleSubmit() {
    isLoading = true;
    error = null;
    
    // Format the amount to always have 2 decimal places
    const formattedAmount = formatAmount(displayValue);
    
    try {
      const response = await fetch(BACKEND_URL, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          target,
          amount: parseFloat(formattedAmount)
        })
      });
      
      if (!response.ok) {
        throw new Error(`Server responded with status: ${response.status}`);
      }
      
      // Convert the response blob to an object URL
      const blob = await response.blob();
      qrCodeSrc = URL.createObjectURL(blob);
      isTargerEntered = true;
    } catch (err) {
      error = err.message || 'Failed to generate QR code';
      console.error(error);
    } finally {
      isLoading = false;
    }
  }

  // Clean up object URL when component is destroyed
  function cleanup() {
    if (qrCodeSrc) {
      URL.revokeObjectURL(qrCodeSrc);
    }
  }

  // Reset form but preserve the target (citizen ID or phone number)
  function resetForm() {
    // Do NOT clear target value to preserve citizen ID or phone number
    clearDisplay();
    error = null;
    
    // Clean up existing QR code if present
    if (qrCodeSrc) {
      URL.revokeObjectURL(qrCodeSrc);
      qrCodeSrc = null;
    }
  }

  // Full reset for the "Clear All" functionality
  function resetAll() {
    target = '';
    isTargerEntered = false;
    resetForm();
  }

  // Watch for changes in target to update button state
  $: {
    target;
    updateButtonState();
  }
</script>

<svelte:window on:beforeunload={cleanup}/>

<div class="container">
  <h1>Thai QR Code Generator</h1>
  
  <form on:submit|preventDefault={handleSubmit} class="form-container">
    <div class="form-group">
      <div class="input-with-clear">
        <div class="input-wrapper">
          <label for="target">Thai ID or Phone Number</label>
          <input
            id="target"
            type="text"
            bind:value={target}
            placeholder="Enter 13-digit Thai ID or 10-digit phone number"
            class:invalid={target && !isValidThaiIdOrPhone(target)}
            disabled={qrCodeSrc !== null || isTargerEntered}
            class:disabled={qrCodeSrc !== null}
          />
        </div>
        {#if target && !qrCodeSrc}
          <button type="button" class="clear-button" on:click={() => target = ''}>×</button>
        {/if}
      </div>
      {#if target && !isValidThaiIdOrPhone(target)}
        <p class="error-message">Please enter a valid Thai ID (13 digits) or phone number (10 digits starting with 0)</p>
      {/if}
    </div>
    
    <div class="form-group">
      <label>{qrCodeSrc ? 'Your QR Code' : 'Amount Calculator'}</label>
      
      {#if qrCodeSrc}
        <!-- QR Code Display -->
        <div class="qr-container">
          <div class="amount-display">Amount: {formatAmount(displayValue)} THB</div>
          <div class="id-display">ID/Phone: {target}</div>
          <img src={qrCodeSrc || "/placeholder.svg"} alt="QR Code" />
        </div>
      {:else}
        <!-- Calculator Pad -->
        <div class="calculator">
          <div class="calculator-display">
            <div class="calculation-history">{calculationHistory}</div>
            <div class="current-value">{displayValue}</div>
          </div>
          <div class="calculator-keypad">
            <div class="calculator-row">
              <button type="button" class="calculator-key" on:click={() => clearDisplay()}>C</button>
              <button type="button" class="calculator-key" on:click={() => handleOperator('/')}>/</button>
              <button type="button" class="calculator-key" on:click={() => handleOperator('*')}>×</button>
              <button type="button" class="calculator-key" on:click={() => handleOperator('-')}>-</button>
            </div>
            <div class="calculator-row">
              <button type="button" class="calculator-key" on:click={() => inputDigit(7)}>7</button>
              <button type="button" class="calculator-key" on:click={() => inputDigit(8)}>8</button>
              <button type="button" class="calculator-key" on:click={() => inputDigit(9)}>9</button>
              <button type="button" class="calculator-key operator" on:click={() => handleOperator('+')}>+</button>
            </div>
            <div class="calculator-row">
              <button type="button" class="calculator-key" on:click={() => inputDigit(4)}>4</button>
              <button type="button" class="calculator-key" on:click={() => inputDigit(5)}>5</button>
              <button type="button" class="calculator-key" on:click={() => inputDigit(6)}>6</button>
              <button type="button" class="calculator-key equals" on:click={() => handleEquals()}>=</button>
            </div>
            <div class="calculator-row">
              <button type="button" class="calculator-key" on:click={() => inputDigit(1)}>1</button>
              <button type="button" class="calculator-key" on:click={() => inputDigit(2)}>2</button>
              <button type="button" class="calculator-key" on:click={() => inputDigit(3)}>3</button>
              <button type="button" class="calculator-key" on:click={() => inputDecimal()}>.</button>
            </div>
            <div class="calculator-row">
              <button type="button" class="calculator-key zero" on:click={() => inputDigit(0)}>0</button>
              <button type="button" class="calculator-key" on:click={() => inputDigit(0)}>&nbsp;</button>
              <button type="button" class="calculator-key" on:click={() => inputDigit(0)}>&nbsp;</button>
            </div>
          </div>
        </div>
      {/if}
    </div>
    
    <div class="button-group">
      <button type="submit" disabled={isButtonDisabled || qrCodeSrc}>
        {isLoading ? 'Generating QR Code...' : 'Generate QR Code'}
      </button>
      <button type="button" class="reset-button" on:click={resetForm}>
        {qrCodeSrc ? 'New QR Code' : 'Reset Calculator'}
      </button>
    </div>
    
    {#if target && !qrCodeSrc}
      <button type="button" class="clear-all-button" on:click={resetAll}>
        Clear All
      </button>
    {/if}
  </form>
  
  {#if error}
    <div class="error-container">
      <p>{error}</p>
    </div>
  {/if}
</div>

<style>
  .container {
    max-width: 600px;
    margin: 0 auto;
    padding: 2rem;
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif;
  }
  
  h1 {
    color: #333;
    margin-bottom: 2rem;
    text-align: center;
  }
  
  .form-container {
    display: flex;
    flex-direction: column;
    align-items: center;
    width: 100%;
  }
  
  .form-group {
    margin-bottom: 1.5rem;
    width: 100%;
    max-width: 400px;
  }
  
  label {
    display: block;
    margin-bottom: 0.5rem;
    font-weight: 600;
  }
  
  .input-with-clear {
    position: relative;
    display: flex;
    align-items: center;
  }
  
  .input-wrapper {
    flex: 1;
  }
  
  .clear-button {
    position: absolute;
    right: 10px;
    top: 50%;
    transform: translateY(-50%);
    background: none;
    border: none;
    color: #999;
    font-size: 1.5rem;
    cursor: pointer;
    padding: 0;
    width: 24px;
    height: 24px;
    display: flex;
    align-items: center;
    justify-content: center;
    border-radius: 50%;
  }
  
  .clear-button:hover {
    background-color: #f1f1f1;
    color: #333;
  }
  
  input {
    width: 100%;
    padding: 0.75rem;
    border: 1px solid #ccc;
    border-radius: 4px;
    font-size: 1rem;
  }
  
  input.invalid {
    border-color: #e74c3c;
  }
  
  input.disabled {
    background-color: #f8f9fa;
    color: #6c757d;
    cursor: not-allowed;
  }
  
  .error-message {
    color: #e74c3c;
    font-size: 0.875rem;
    margin-top: 0.5rem;
  }
  
  /* Calculator styles */
  .calculator {
    border: 1px solid #ccc;
    border-radius: 4px;
    overflow: hidden;
    box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
  }
  
  .calculator-display {
    background-color: #f8f9fa;
    padding: 1rem;
    text-align: right;
    border-bottom: 1px solid #ddd;
  }
  
  .calculation-history {
    font-size: 0.875rem;
    color: #6c757d;
    min-height: 1.25rem;
    margin-bottom: 0.25rem;
  }
  
  .current-value {
    font-size: 1.5rem;
    font-weight: bold;
  }
  
  .calculator-keypad {
    display: grid;
    grid-template-rows: repeat(5, 1fr);
  }
  
  .calculator-row {
    display: grid;
    grid-template-columns: repeat(4, 1fr);
  }
  
  .calculator-key {
    padding: 1rem 0;
    font-size: 1.25rem;
    border: none;
    border-right: 1px solid #ddd;
    border-bottom: 1px solid #ddd;
    background-color: white;
    color: black;
    cursor: pointer;
    transition: background-color 0.2s;
  }
  
  .calculator-key:last-child {
    border-right: none;
  }
  
  .calculator-row:last-child .calculator-key {
    border-bottom: none;
  }
  
  .calculator-key:hover {
    background-color: #f1f3f5;
  }
  
  .calculator-key:active {
    background-color: #e9ecef;
  }
  
  .calculator-key.operator {
    background-color: #e9ecef;
  }
  
  .calculator-key.equals {
    background-color: #3498db;
    color: white;
    grid-row: span 2;
  }
  
  .calculator-key.zero {
    grid-column: span 2;
  }
  
  /* QR Code styles */
  .qr-container {
    border: 1px solid #ccc;
    border-radius: 4px;
    overflow: hidden;
    box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
    padding: 1rem;
    text-align: center;
  }
  
  .amount-display {
    font-size: 1.25rem;
    font-weight: bold;
    margin-bottom: 0.5rem;
    color: #333;
  }
  
  .id-display {
    font-size: 1rem;
    color: #6c757d;
    margin-bottom: 1rem;
  }
  
  .qr-container img {
    max-width: 100%;
    height: auto;
    border: 1px solid #eee;
    border-radius: 4px;
  }
  
  /* Button styles */
  button {
    background-color: #3498db;
    color: white;
    border: none;
    border-radius: 4px;
    padding: 0.75rem 1.5rem;
    font-size: 1rem;
    cursor: pointer;
    transition: background-color 0.2s;
  }
  
  .button-group {
    display: flex;
    gap: 1rem;
    margin-top: 1rem;
    width: 100%;
    max-width: 400px;
  }
  
  .button-group button {
    flex: 1;
  }
  
  button.reset-button {
    background-color: #e74c3c;
  }
  
  button.reset-button:hover {
    background-color: #c0392b;
  }
  
  button:hover:not(:disabled) {
    background-color: #2980b9;
  }
  
  button:disabled {
    background-color: #95a5a6;
    cursor: not-allowed;
  }
  
  .clear-all-button {
    margin-top: 1rem;
    background-color: #95a5a6;
    font-size: 0.875rem;
    padding: 0.5rem 1rem;
  }
  
  .clear-all-button:hover {
    background-color: #7f8c8d;
  }
  
  .error-container {
    background-color: #fdeaea;
    border: 1px solid #e74c3c;
    border-radius: 4px;
    padding: 1rem;
    margin-top: 1.5rem;
    width: 100%;
    max-width: 400px;
  }
  
  h2 {
    margin-bottom: 1rem;
    color: #333;
  }
</style>