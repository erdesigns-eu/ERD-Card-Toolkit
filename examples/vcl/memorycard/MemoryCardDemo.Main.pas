unit MemoryCardDemo.Main;

interface

uses ERD.Card.Demo.FamilyForm;

type
  /// <summary>Native family form alias using the shared form resource and worker lifecycle.</summary>
  TMemoryCardDemoForm = TCardFamilyForm;

var
  /// <summary>Application-owned instance of the explicitly selected family demo.</summary>
  MemoryCardDemoForm: TMemoryCardDemoForm;

implementation

end.
