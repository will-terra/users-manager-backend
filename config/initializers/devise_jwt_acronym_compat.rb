# Compatibility shim: when 'JWT' is registered as an acronym the
# inflector will classify `:jwt_authenticatable` as `JWTAuthenticatable`.
# Devise defines the module as `JwtAuthenticatable` (capital J only). To
# avoid an uninitialized constant error, alias the constant when needed.
if defined?(Devise::Models) && defined?(Devise::Models::JwtAuthenticatable) &&
   !defined?(Devise::Models::JWTAuthenticatable)
  Devise::Models.const_set("JWTAuthenticatable", Devise::Models::JwtAuthenticatable)
end
