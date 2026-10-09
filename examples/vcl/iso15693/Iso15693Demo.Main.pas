unit Iso15693Demo.Main;

interface

uses ERD.Card.Demo.FamilyForm;

type
  /// <summary>Native family form alias using the shared form resource and worker lifecycle.</summary>
  TIso15693DemoForm = TCardFamilyForm;

var
  /// <summary>Application-owned instance of the explicitly selected family demo.</summary>
  Iso15693DemoForm: TIso15693DemoForm;

implementation

end.
