require 'base64'
require 'pbkdf2'
require 'rbnacl'

# A SecretBox that (like RandomNonceBox) automatically generates a suitable
# nonce, but also which uses PBKDF2 to derive a password of the right length.
class PasswordBox < RbNaCl::SecretBox
  DEFAULT_PBKDF2_ITERS = 5000

  # Create a new PasswordBox
  #
  # @param password [String] A password of any length
  def initialize(password)
    @password = password
  end

  # Encrypts the message using a salted key derived from the given password, and
  # a random nonce.
  #
  # @param message [String] The message to encrypt
  #
  # @return [String] The encrypted message
  def box(message)
    nonce = generate_nonce
    salt, iters, @key = generate_key
    ciphertext = super(nonce, message)

    Base64.encode64(nonce + salt + iters + ciphertext)
  end
  alias encrypt box

  # Decrypts the message. Extracts both the encryption nonce and the salt from
  # the message.
  #
  # @param enciphered_message [String] The message to decrypt
  #
  # @raise [CryptoError] If the message has been tampered with.
  #
  # @return [String] The plaintext of the message
  def open(enciphered_message)
    decoded = Base64.decode64(enciphered_message)
    nonce, salt, iters, ciphertext = extract(decoded)
    @key = generate_key(salt, iters).last
    super(nonce, ciphertext)
  end
  alias decrypt open

  private
  def generate_nonce
    RbNaCl::Random.random_bytes(nonce_bytes)
  end
  def generate_key(salt=nil, iters=DEFAULT_PBKDF2_ITERS)
    salt ||= generate_nonce
    key = PBKDF2.new(
      :password => @password,
      :salt => salt,
      :iterations => iters,
      :hash_function => :sha256,
      :key_length => key_bytes
    )
    [salt, [iters].pack("N"), key.bin_string]
  end
  def extract(bytes)
    nonce = bytes.slice!(0, nonce_bytes)
    salt = bytes.slice!(0, nonce_bytes)
    iters = bytes.slice!(0, 4).unpack("N").first
    [nonce, salt, iters, bytes]
  end
end
