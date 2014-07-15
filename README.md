# NAME

HTML::FormHandlerX::Field::JavaScript - a script tag with javascript code supplied via field for HTML::FormHandler.

# VERSION

version 0.001

# SYNOPSIS

This class can be used for fields that need to supply JavaScript code
for use by scripts in the form. It will render the value returned by a
form's `js_code_[field_name]` method, or the field's `js_code`
attribute.

    has_field 'user_update' => ( type => 'JavaScript',
       js_code => q`$('#fldId').on('change', myFunction);`
    );

or using a method:

    has_field 'user_update' => ( type => 'JavaScript' );
    sub js_code_user_update {
       my ( $self, $field ) = @_;
       if( $self->something ) {
          return q`$('#fldId').on('change', myFunction);`;
       }
       else {
          return q`$('#otherFldId').on('change', myOtherFunction);`;
       }
    }
    #----
    has_field 'usernames' => ( type => 'JavaScript' );
    sub js_code_usernames {
        my ( $self, $field ) = @_;
        return q`$('#fldId').on('change', myFunction);`;
    }

or set the name of the rendering method:

    has_field 'user_update' => ( type => 'JavaScript', set_js_code => 'my_user_update' );
    sub my_user_update {
      ....
    }

or provide a 'render\_method':

     has_field 'user_update' => ( type => 'JavaScript', render_method => \&render_user_update );
     sub render_user_update {
         my $self = shift;
         ....
         return q(
  <script type="text/javascript">
    // code here
  </script>);
     }

# FIELD OPTIONS

We support the following additional field options, over what is inherited from
[HTML::FormHandler::Field](https://metacpan.org/pod/HTML::FormHandler::Field)

## do\_minify

Boolean to indicate whether code should be minified using [JavaScript::Minifier::XS](https://metacpan.org/pod/JavaScript::Minifier::XS)

# AUTHOR

Charlie Garrison <garrison@zeta.org.au>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Charlie Garrison.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
