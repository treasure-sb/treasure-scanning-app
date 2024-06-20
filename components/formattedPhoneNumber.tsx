export const formatPhoneNumber = (phoneNumber: any) => {
    // Ensure the input is a string and contains exactly 10 digits
    if (typeof phoneNumber !== 'string' || phoneNumber.length !== 10 || !/^\d{10}$/.test(phoneNumber)) {
      throw new Error('Input must be a 10-digit phone number string.');
    }
  
    // Use a regular expression to capture the parts of the phone number
    const formattedPhoneNumber = phoneNumber.replace(/(\d{3})(\d{3})(\d{4})/, '($1) $2-$3');
  
    return formattedPhoneNumber;
  };
