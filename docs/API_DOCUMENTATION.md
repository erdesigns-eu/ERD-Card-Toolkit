# Delphi API documentation

Every exported declaration and public/published member receives English Delphi
XML documentation directly above its declaration. Also document protected extension
points. This includes classes, interfaces, records, helpers, aliases, enum values,
callbacks, constructors, destructors, overloads, methods, properties, fields, events,
global variables, constants and resourcestrings.

Use Embarcadero's `///` syntax and supported XML tags:

- `summary`: a meaningful description on every API declaration.
- `param`: exact parameter names and input/output contracts.
- `returns`: exactly one on functions that return a value; none on procedures.
- `remarks`: ownership, units, indexing, empty/invalid input, limits, thread and lifecycle behavior.
- `exception cref="..."`: exceptions that form part of the actual contract.
- `see cref="..."`, `para`, `c`, `code`: links and formatting where useful.

Close tags and escape XML text. Document every overload independently. Never describe
an error returned by a Try method as an exception unless that method actually throws it.
Do not log or reproduce sensitive card data in parser exceptions.

```pascal
/// <summary>Compares byte arrays by their contents.</summary>
/// <param name="ALeft">The first array.</param>
/// <param name="ARight">The second array.</param>
/// <returns>True if the lengths and bytes match.</returns>
function BytesEqual(const ALeft: TBytes; const ARight: TBytes): Boolean;
```

## Verification

`check_xmldoc.py` is included in the Pascalcheck core profile. It checks visible API
coverage, XML syntax, summary/parameter/result tags and reference attributes. It fails
visibly for unsupported declaration forms, including variant and anonymous records;
extend the reader with positive/negative fixtures before introducing such public APIs.
It is not a Delphi compiler, an XML-reference resolver or a language server.

The documentation reader has regression fixtures for enums, callback and method-reference
types, interfaces, records, helpers, visibility, properties, overloads and globals.
Removing a declaration's summary, breaking XML or changing parameter names must fail.

Compile with `--doc`, or enable **Generate XML Documentation** in
Project > Options > Delphi Compiler > Compiling > Other Options. The compiler exports
handwritten comments in `devnotes`. Inspect Help Insight via hover or Ctrl+Shift+H in a
consumer project that uses the actual distributed source/package. Correct XML alone
does not prove IDE integration; check unit search paths and the intended Delphi versions.

Official references:

- [XML Documentation Comments](https://docwiki.embarcadero.com/RADStudio/Florence/en/XML_Documentation_Comments)
- [Help Insight](https://docwiki.embarcadero.com/RADStudio/Florence/en/Help_Insight)
- [XML Documentation for Delphi Code](https://docwiki.embarcadero.com/RADStudio/Florence/en/XML_Documentation_for_Delphi_Code)
