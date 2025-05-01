<script>
  import { onMount } from 'svelte';
  
  let inputValue = '';
  let qrCodeSrc = '';
  let isLoading = false;
  let errorMessage = '';
  let isValid = false;
  
  // Validate Thai phone number (10 digits starting with 0)
  // or Thai citizen ID (13 digits)
  function validateInput(value) {
    const phoneRegex = /^0\d{9}$/;
    const citizenIdRegex = /^\d{13}$/;
    
    return phoneRegex.test(value) || citizenIdRegex.test(value);
  }
  
  function handleInput() {
    errorMessage = '';
    isValid = validateInput(inputValue);
    
    if (inputValue && !isValid) {
      errorMessage = 'Please enter a valid Thai phone number (10 digits starting with 0) or citizen ID (13 digits)';
    }
  }
  
  async function handleSubmit() {
    if (!isValid) {
      errorMessage = 'Please enter a valid Thai phone number or citizen ID';
      return;
    }
    
    isLoading = true;
    errorMessage = '';
    
    try {
      // Replace with your actual API endpoint
      const response = await fetch('/api/generate-qr', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ value: inputValue })
      });
      
      if (!response.ok) {
        throw new Error('Failed to generate QR code');
      }
      
      // Get the image data from the response
      const blob = await response.blob();
      qrCodeSrc = URL.createObjectURL(blob);
    } catch (error) {
      console.error('Error generating QR code:', error);
      errorMessage = 'Failed to generate QR code. Please try again.';
    } finally {
      isLoading = false;
    }
  }
  
  // Clean up object URL when component is destroyed
  onMount(() => {
    return () => {
      if (qrCodeSrc) {
        URL.revokeObjectURL(qrCodeSrc);
      }
    };
  });
</script>

<div class="container">
  <h1>Thai ID/Phone QR Generator</h1>
  
  <form on:submit|preventDefault={handleSubmit}>
    <div class="input-group">
      <label for="id-input">Enter Thai Phone Number or Citizen ID</label>
      <input
        id="id-input"
        type="text"
        bind:value={inputValue}
        on:input={handleInput}
        placeholder="Phone number or Citizen ID"
        class:error={errorMessage}
      />
      {#if errorMessage}
        <p class="error-message">{errorMessage}</p>
      {/if}
    </div>
    
    <button type="submit" disabled={!isValid || isLoading}>
      {isLoading ? 'Generating...' : 'Generate QR Code'}
    </button>
  </form>
  
  {#if isLoading}
    <div class="loading">
      <p>Generating QR code...</p>
    </div>
  {:else if qrCodeSrc}
    <div class="qr-container">
      <h2>Your QR Code</h2>
      <img src={qrCodeSrc || "/placeholder.svg"} alt="QR Code" />
      <p class="info">QR code for: {inputValue}</p>
    </div>
  {/if}
</div>

<style>
  .container {
    max-width: 500px;
    margin: 0 auto;
    padding: 2rem;
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif;
  }
  
  h1 {
    color: #333;
    text-align: center;
    margin-bottom: 2rem;
  }
  
  .input-group {
    margin-bottom: 1.5rem;
  }
  
  label {
    display: block;
    margin-bottom: 0.5rem;
    font-weight: 500;
  }
  
  input {
    width: 100%;
    padding: 0.75rem;
    border: 1px solid #ccc;
    border-radius: 4px;
    font-size: 1rem;
  }
  
  input.error {
    border-color: #e53e3e;
  }
  
  .error-message {
    color: #e53e3e;
    margin-top: 0.5rem;
    font-size: 0.875rem;
  }
  
  button {
    width: 100%;
    padding: 0.75rem;
    background-color: #4f46e5;
    color: white;
    border: none;
    border-radius: 4px;
    font-size: 1rem;
    font-weight: 500;
    cursor: pointer;
    transition: background-color 0.2s;
  }
  
  button:hover:not(:disabled) {
    background-color: #4338ca;
  }
  
  button:disabled {
    background-color: #a5b4fc;
    cursor: not-allowed;
  }
  
  .loading {
    text-align: center;
    margin-top: 2rem;
  }
  
  .qr-container {
    margin-top: 2rem;
    text-align: center;
  }
  
  .qr-container img {
    max-width: 100%;
    height: auto;
    border: 1px solid #e2e8f0;
    border-radius: 4px;
    padding: 1rem;
    background-color: white;
  }
  
  h2 {
    margin-bottom: 1rem;
    color: #333;
  }
  
  .info {
    margin-top: 1rem;
    color: #4b5563;
  }
</style>