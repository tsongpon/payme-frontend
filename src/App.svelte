<script>
  // State variables
  let target = '';
  let amount = '';
  let isLoading = false;
  let qrCodeSrc = null;
  let error = null;
  let isButtonDisabled = true;

  // Backend service URL
  const BACKEND_URL = "http://localhost:1323/qrcode";

  // Validation functions
  function isValidThaiIdOrPhone(value) {
    // Thai citizen ID: 13 digits
    const thaiIdPattern = /^\d{13}$/;
    
    // Thai mobile phone: 10 digits starting with 0
    const thaiPhonePattern = /^0\d{9}$/;
    
    return thaiIdPattern.test(value) || thaiPhonePattern.test(value);
  }

  function isValidAmount(value) {
    // Number with exactly 2 decimal places
    const amountPattern = /^\d+\.\d{2}$/;
    return amountPattern.test(value);
  }

  // Format amount to always have 2 decimal places
  function formatAmount(value) {
    // If empty, return empty
    if (!value) return '';
    
    // If it's just a number without decimal point
    if (/^\d+$/.test(value)) {
      return `${value}.00`;
    }
    
    // If it has a decimal point but not exactly 2 decimal places
    if (/^\d+\.\d{0,1}$/.test(value)) {
      return value.includes('.') ? 
        value.padEnd(value.indexOf('.') + 3, '0') : 
        `${value}.00`;
    }
    
    return value;
  }

  // Handle amount input change
  function handleAmountChange() {
    // Only format if there's a value and it's not already properly formatted
    if (amount && !isValidAmount(amount)) {
      amount = formatAmount(amount);
    }
  }

  // Computed property for button disabled state
  $: isButtonDisabled = !isValidThaiIdOrPhone(target) || !isValidAmount(amount) || isLoading;

  // Handle form submission
  async function handleSubmit() {
    isLoading = true;
    error = null;
    qrCodeSrc = null;
    
    try {
      const response = await fetch(BACKEND_URL, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          target,
          amount: parseFloat(amount)
        })
      });
      
      if (!response.ok) {
        throw new Error(`Server responded with status: ${response.status}`);
      }
      
      // Convert the response blob to an object URL
      const blob = await response.blob();
      qrCodeSrc = URL.createObjectURL(blob);
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

  // Reset all form values and clear QR code
  function resetForm() {
    target = '';
    amount = '';
    error = null;
    
    // Clean up existing QR code if present
    if (qrCodeSrc) {
      URL.revokeObjectURL(qrCodeSrc);
      qrCodeSrc = null;
    }
  }
</script>

<svelte:window on:beforeunload={cleanup}/>

<div class="container">
  <h1>Thai QR Code Generator</h1>
  
  <form on:submit|preventDefault={handleSubmit} class="form-container">
    <div class="form-group">
      <label for="target">Thai ID or Phone Number</label>
      <input
        id="target"
        type="text"
        bind:value={target}
        placeholder="Enter 13-digit Thai ID or 10-digit phone number"
        class:invalid={target && !isValidThaiIdOrPhone(target)}
      />
      {#if target && !isValidThaiIdOrPhone(target)}
        <p class="error-message">Please enter a valid Thai ID (13 digits) or phone number (10 digits starting with 0)</p>
      {/if}
    </div>
    
    <div class="form-group">
      <label for="amount">Amount (with 2 decimal places)</label>
      <input
        id="amount"
        type="text"
        bind:value={amount}
        on:blur={handleAmountChange}
        placeholder="Enter amount (e.g., 100.00)"
        class:invalid={amount && !isValidAmount(amount)}
      />
      {#if amount && !isValidAmount(amount)}
        <p class="error-message">Please enter a valid amount with exactly 2 decimal places (e.g., 100.00)</p>
      {/if}
    </div>
    
    <div class="button-group">
      <button type="submit" disabled={isButtonDisabled}>
        {isLoading ? 'Generating QR Code...' : 'Generate QR Code'}
      </button>
      <button type="button" class="reset-button" on:click={resetForm}>
        Reset
      </button>
    </div>
  </form>
  
  {#if error}
    <div class="error-container">
      <p>{error}</p>
    </div>
  {/if}
  
  {#if qrCodeSrc}
    <div class="qr-container">
      <h2>Your QR Code</h2>
      <img src={qrCodeSrc || "/placeholder.svg"} alt="QR Code" />
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
    max-width: 400px; /* Limit width to align with buttons */
  }
  
  label {
    display: block;
    margin-bottom: 0.5rem;
    font-weight: 600;
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
  
  .error-message {
    color: #e74c3c;
    font-size: 0.875rem;
    margin-top: 0.5rem;
  }
  
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
    max-width: 400px; /* Match the width of form-group */
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
  
  .error-container {
    background-color: #fdeaea;
    border: 1px solid #e74c3c;
    border-radius: 4px;
    padding: 1rem;
    margin-top: 1.5rem;
    width: 100%;
    max-width: 400px;
  }
  
  .qr-container {
    margin-top: 2rem;
    text-align: center;
    width: 100%;
    max-width: 400px;
  }
  
  .qr-container img {
    max-width: 100%;
    height: auto;
    border: 1px solid #eee;
    border-radius: 4px;
    box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
  }
  
  h2 {
    margin-bottom: 1rem;
    color: #333;
  }
</style>