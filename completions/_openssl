#compdef openssl
#
# Retrieved from:
#  https://github.com/aschrab/zsh-completions/blob/openssl/src/_openssl

# _openssl: Start point {{{
_openssl() {
  setopt nonomatch
  local openssl==openssl

  if [[ $openssl = '=openssl' ]]; then
    _message "openssl executable not found: completion not available"
    return
  fi

  _get_openssl_commands

  if (( CURRENT > 2 )); then
    _openssl_dispatch
  else
    _openssl_commands
  fi
}
# }}}

# _get_openssl_commands: Populate arrays of subcommand names {{{
_get_openssl_commands() {
  if ! (( ${+_openssl_list_cmd_list} )); then
    typeset -ga _openssl_list_cmd_list
    _openssl_list_cmd_list=(
      list-standard-commands
      list-message-digest-commands
      list-cipher-commands
      list-cipher-algorithms
      list-message-digest-algorithms
      list-public-key-algorithms
    )
  fi

  if ! (( ${+_openssl_standard_cmd_list} )); then
    typeset -ga _openssl_standard_cmd_list
    _openssl_standard_cmd_list=( $(openssl list-standard-commands) )
  fi

  if ! (( ${+_openssl_digest_cmd_list} )); then
    typeset -ga _openssl_digest_cmd_list
    _openssl_digest_cmd_list=( $(openssl list-message-digest-commands) )
  fi

  if ! (( ${+_openssl_cipher_cmd_list} )); then
    typeset -ga _openssl_cipher_cmd_list
    _openssl_cipher_cmd_list=( $(openssl list-cipher-commands) )
  fi
}
# }}}

# _openssl_commands: complete subcommand name  {{{
_openssl_commands() {
  integer ret=1
  _describe -t cipher-commands 'Cipher command' _openssl_cipher_cmd_list && ret=0
  _describe -t digest-commands 'Digest command' _openssl_digest_cmd_list && ret=0
  _describe -t standard-commands 'Standard command' _openssl_standard_cmd_list && ret=0
  _describe -t list-commands 'List commands' _openssl_list_cmd_list && ret=0

  return ret
}
# }}}

# _openssl_dispatch: Dispatch to completion for subcommand  {{{
_openssl_dispatch() {
  integer ret=1
  shift words
  (( CURRENT-- ))

  # Check if there's a completion function for the specific subcommand
  if (( $+functions[_openssl-$words[1]] )); then
    _call_function ret _openssl-$words[1]
  # Digest commands can be handled by a common function
  elif (( $+_openssl_digest_cmd_list )); then
    _openssl_digest_command
  else
    _message "Can't dispatch to $words[1]"
  fi

  return ret
}
# }}}

# Completion for option arguments {{{
# _openssl_pass_source: Complete password source info {{{
_openssl_pass_source() {
  _values -S : 'Password source' \
    'pass[Direct password entry]:password:' \
    'env[Get password from named environment variable]:environment:_parameters -g "*export*"' \
    'file[Get password from file]:password file:_files' \
    'fd[Read password from file descriptor #]:integer:' \
    'stdin[Read password from standard input]'
}
# }}}

# _openssl_engine_id: Complete engine ID {{{
_openssl_engine_id() {
  # TODO
}
#}}}

# _openssl_x509_name_options: Complete x509 name options {{{
_openssl_x509_name_options() {
  local sep='sep_comma_plus sep_comma_plus_space sep_semi_plus_space sep_multiline'
  local fname='nofname sname lname oid'

  _values -s , -w 'name options' \
    'compat[Use old format (default)]' \
    'RFC2253[RFC2253 compatible]' \
    'oneline[Single line format]' \
    'multiline[Multi line format]' \
    'esc_2253[Escape special characters: ,+"<>]' \
    'esc_ctrl[Escape control characters]' \
    'esc_msb[Escape characters with ASCII value > 127]' \
    'use_quote[Surround entire string with double quote]' \
    'utf8[Convert all strings to UTF8]' \
    'no_type[Dump multibyte characters without conversion]' \
    'show_type[Precede field content with type of ASN1 string]' \
    'dump_der[Use DER encoding for hexdump]' \
    'dump_nostr[dump types which are not character strings]' \
    'dump_all[dump all fields]' \
    'dump_unknown[dump any field with unknown OID]' \
    "($sep)sep_comma_plus[use , and + as separators]" \
    "($sep)sep_comma_plus_space[use , and + with following space as separators]" \
    "($sep)sep_semi_plus_space[use ; and + with following space as separators]" \
    "($sep)sep_multiline[use LF and + as separators]" \
    'dn_rev[reverse fields of the DN]' \
    "($fname)nofname[do not display field name]" \
    "($fname)sname[display short field name]" \
    "($fname)lname[display long field name]" \
    "($fname)oid[use numerical OID for field name]" \
    'align[align field values (only usable with sep_multiline)]' \
    'space_eq[put spaces around = after field name]'
}
#}}}

# _openssl_x509_cert_options: Complete x509 certificate options {{{
_openssl_x509_cert_options() {
  # TODO
}
#}}}

# _openssl_req_newkey_options: Complete options for req -newkey {{{
_openssl_req_newkey_options() {
  # TODO: Get list of algorithms dynamically
  _values -S : 'Key options' \
    'rsa[RSA key]::number of bits:' \
    'param[Read paramaters from file]:parameter file:_files' \
    'cmac' \
    'hmac'
}
#}}}

#}}}

# _openssl_digest_command: Default completion for digest subcommands {{{
_openssl_digest_command() {
  _arguments : \
    '-c[Print digest in two-digit groups separated by colons]' \
    '-d[Print BIO debugging information]' \
    '(-binary)-hex[Output digest as a hex dump]' \
    '(-hex -c)-binary[Output digest or signature in binary form]' \
    '-hmac[Set the HMAC key to ARG]:arg:' \
    '-non-fips-allow[Allow use of non-FIPS digest]' \
    '-out[Filename for output]:output file:_files' \
    '-sign[Sign the digest using key in file]:key file:_files' \
    '-keyform[Key format]:format:(PEM ENGINE)' \
    '-engine[Use engine ID]:Engine ID:_openssl_engine_id' \
    '-sigopt[Signature options]:Signature option:' \
    '-passin[Private key password source]:Key source:_openssl_pass_source' \
    '-verify[Verify signature with public key FILE]:Public key file:_files' \
    '-prverify[Verify signature with private key FILE]:Private key file:_files' \
    '-signature[Verify signature in FILE]:Signature file:_files' \
    '-mac[Message Authenticate Code algorithm]:MAC algorithm:' \
    '-macopt[Options to pass to MAC algorithm]:MAC options:' \
    '-rand[File for random data]:Random source:_files' \
    '*: :_files'
}
#}}}

# Completion for specific subcommands {{{

_openssl-req() { #{{{
  local -a digests
  digests=(-md5 -sha1) # FIXME generate this
  _arguments : \
    $digests \
    '-inform[Format of the input]:input format:(DER PEM)' \
    '-outform[Format to use for the output]:output format:(DER PEM)' \
    '-in[Input filename]:input file:_files' \
    '-passsin[Source for password of the input]:password source:_openssl_pass_source' \
    '-out[Output file name]:output file:_files' \
    '-passsout[Source for password of the output]:password source:_openssl_pass_source' \
    '-text[Print certificate request in text form]' \
    '-subject[Print request subject]' \
    '-pubkey[Output the public key]' \
    '-noout[Prevent output of encoded request]' \
    '-modulus[Print the public key modulus]' \
    '-verify[Verify request signature]' \
    '-new[Generate a new certificate request]' \
    '-subj[Specify subject of the request]:subject:' \
    '-rand[File for random data]:Random source:_files' \
    '-newkey[Create a new private key and request]:key spec:_openssl_req_newkey_options' \
    '-pkeyopt[Public key option]:key option:' \
    '-key[Key from which private key will be read]:private key file:_files' \
    '-keyform[Format of file specified by -key option]:key format:(DER PEM)' \
    '-keyout[File name to which generated key should be written]:output key file:_files' \
    '-nodes[Do not encrypt generated private key]' \
    '-config[Alternate configuration file]:config file:_files' \
    '-multivalue-rdn[Interpret -subj argument with support for multivalued RDNs]' \
    '-x509[Output a self signed certificate]' \
    '-days[Number of days for which -x509 certifcate will be valid]:integer:' \
    '-set_serial[Serial number for self-signed certificate]:integer:' \
    {-extensions,-reqexts}'[]:section:' \
    '-utf8[Interpret values as UTF8 strings]' \
    '*-nameopt[Options for display of subject or issuer name]:name option:_openssl_x509_name_options' \
    '-reqopt[Customise output format for -text]:request option:_openssl_x509_cert_options' \
    '-asn1-kludge[Produce broken output required by some CAs]' \
    '-no-asn1-kludge[Produce standard-compliant output]' \
    '-newhdr[Add NEW to the PEM header and footer]' \
    '-batch[Non-interactive mode]' \
    '-verbose[Print extra details]' \
    '-engine[Use engine ID]:Engine ID:_openssl_engine_id' \
    '-keygen_engine[Use engine ID for key generation]:Engine ID:_openssl_engine_id'
}
#}}}

#}}}

_openssl "$@"

# Local Variables:
# mode: Shell-Script
# sh-indentation: 2
# indent-tabs-mode: nil
# sh-basic-offset: 2
# End:
# vim: filetype=zsh expandtab shiftwidth=2 foldmethod=marker
