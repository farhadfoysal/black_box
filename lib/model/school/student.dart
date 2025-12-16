import 'dart:typed_data';
import 'package:intl/intl.dart';

/// Student model with advanced professional features
class Student {
  // Fields
  int? _id;
  int? _program;
  String? _studentId;
  String? _uId;
  String? _sId;
  String? _stdId;
  String? _stdName;
  String? _stdPhone;
  String? _stdEmail;
  String? _homePhone;
  String? _stdReligion;
  String? _address;
  String? _dob;
  String? _nidBirth;
  String? _country;
  String? _unionWord;
  String? _fatherName;
  String? _motherName;
  String? _fNid;
  String? _mNid;
  String? _gName;
  String? _gAddress;
  String? _gPhone;
  String? _gEmail;
  String? _stdImg;
  String? _major;
  String? _sMajor;
  String? _stdPass;
  String? _gender;
  String? _addDate;
  int? _aStatus;
  Uint8List? _imgData;
  String? _syncKey;
  String? _key;
  int _syncStatus;
  String? _uniqueId;
  String? _currSessId;

  /// Local image path (offline)
  String? _imagePath;

  /// 0 = pending, 1 = synced
  int _imageSyncStatus;

  // Constructor
  Student({
    int? id,
    int? program,
    String? studentId,
    String? uId,
    String? sId,
    String? stdId,
    String? stdName,
    String? stdPhone,
    String? stdEmail,
    String? homePhone,
    String? stdReligion,
    String? address,
    String? dob,
    String? nidBirth,
    String? country,
    String? unionWord,
    String? fatherName,
    String? motherName,
    String? fNid,
    String? mNid,
    String? gName,
    String? gAddress,
    String? gPhone,
    String? gEmail,
    String? stdImg,
    String? major,
    String? sMajor,
    String? stdPass,
    String? gender,
    String? addDate,
    int? aStatus,
    String? syncKey,
    String? key,
    int syncStatus = 0,
    String? uniqueId,
    String? currSessId,
    String? imagePath,
    int imageSyncStatus = 0,
  })  : _id = id,
        _program = program,
        _studentId = studentId,
        _uId = uId,
        _sId = sId,
        _stdId = stdId,
        _stdName = stdName,
        _stdPhone = stdPhone,
        _stdEmail = stdEmail,
        _homePhone = homePhone,
        _stdReligion = stdReligion,
        _address = address,
        _dob = dob,
        _nidBirth = nidBirth,
        _country = country,
        _unionWord = unionWord,
        _fatherName = fatherName,
        _motherName = motherName,
        _fNid = fNid,
        _mNid = mNid,
        _gName = gName,
        _gAddress = gAddress,
        _gPhone = gPhone,
        _gEmail = gEmail,
        _stdImg = stdImg,
        _major = major,
        _sMajor = sMajor,
        _stdPass = stdPass,
        _gender = gender,
        _addDate = addDate,
        _aStatus = aStatus,
        _syncKey = syncKey,
        _key = key,
        _syncStatus = syncStatus,
        _uniqueId = uniqueId,
        _currSessId = currSessId,
        _imagePath = imagePath,
        _imageSyncStatus = imageSyncStatus;

  // Getters and Setters
  int? get id => _id;
  set id(int? value) => _id = value;

  int? get program => _program;
  set program(int? value) => _program = value;

  String? get studentId => _studentId;
  set studentId(String? value) => _studentId = value;

  String? get uId => _uId;
  set uId(String? value) => _uId = value;

  String? get sId => _sId;
  set sId(String? value) => _sId = value;

  String? get stdId => _stdId;
  set stdId(String? value) => _stdId = value;

  String? get stdName => _stdName;
  set stdName(String? value) => _stdName = value;

  String? get stdPhone => _stdPhone;
  set stdPhone(String? value) => _stdPhone = value;

  String? get stdEmail => _stdEmail;
  set stdEmail(String? value) => _stdEmail = value;

  String? get homePhone => _homePhone;
  set homePhone(String? value) => _homePhone = value;

  String? get stdReligion => _stdReligion;
  set stdReligion(String? value) => _stdReligion = value;

  String? get address => _address;
  set address(String? value) => _address = value;

  String? get dob => _dob;
  set dob(String? value) => _dob = value;

  String? get nidBirth => _nidBirth;
  set nidBirth(String? value) => _nidBirth = value;

  String? get country => _country;
  set country(String? value) => _country = value;

  String? get unionWord => _unionWord;
  set unionWord(String? value) => _unionWord = value;

  String? get fatherName => _fatherName;
  set fatherName(String? value) => _fatherName = value;

  String? get motherName => _motherName;
  set motherName(String? value) => _motherName = value;

  String? get fNid => _fNid;
  set fNid(String? value) => _fNid = value;

  String? get mNid => _mNid;
  set mNid(String? value) => _mNid = value;

  String? get gName => _gName;
  set gName(String? value) => _gName = value;

  String? get gAddress => _gAddress;
  set gAddress(String? value) => _gAddress = value;

  String? get gPhone => _gPhone;
  set gPhone(String? value) => _gPhone = value;

  String? get gEmail => _gEmail;
  set gEmail(String? value) => _gEmail = value;

  String? get stdImg => _stdImg;
  set stdImg(String? value) => _stdImg = value;

  String? get major => _major;
  set major(String? value) => _major = value;

  String? get sMajor => _sMajor;
  set sMajor(String? value) => _sMajor = value;

  String? get stdPass => _stdPass;
  set stdPass(String? value) => _stdPass = value;

  String? get gender => _gender;
  set gender(String? value) => _gender = value;

  String? get addDate => _addDate;
  set addDate(String? value) => _addDate = value;

  int? get aStatus => _aStatus;
  set aStatus(int? value) => _aStatus = value;


  String? get syncKey => _syncKey;
  set syncKey(String? value) => _syncKey = value;

  int get syncStatus => _syncStatus;
  set syncStatus(int value) => _syncStatus = value;

  String? get uniqueId => _uniqueId;
  set uniqueId(String? value) => _uniqueId = value;

  String? get currSessId => _currSessId;
  set currSessId(String? value) => _currSessId = value;

  String? get imagePath => _imagePath;
  set imagePath(String? value) => _imagePath = value;

  int get imageSyncStatus => _imageSyncStatus;
  set imageSyncStatus(int value) => _imageSyncStatus = value;

  /// Convert Student object to Map
  Map<String, dynamic> toMap() => {
    'id': _id,
    'program': _program,
    'studentId': _studentId,
    'uId': _uId,
    'sId': _sId,
    'stdId': _stdId,
    'stdName': _stdName,
    'stdPhone': _stdPhone,
    'stdEmail': _stdEmail,
    'homePhone': _homePhone,
    'stdReligion': _stdReligion,
    'address': _address,
    'dob': _dob,
    'nidBirth': _nidBirth,
    'country': _country,
    'unionWord': _unionWord,
    'fatherName': _fatherName,
    'motherName': _motherName,
    'fNid': _fNid,
    'mNid': _mNid,
    'gName': _gName,
    'gAddress': _gAddress,
    'gPhone': _gPhone,
    'gEmail': _gEmail,
    'stdImg': _stdImg,
    'major': _major,
    'sMajor': _sMajor,
    'stdPass': _stdPass,
    'gender': _gender,
    'addDate': _addDate,
    'aStatus': _aStatus,
    'syncKey': _syncKey,
    'syncStatus': _syncStatus,
    'uniqueId': _uniqueId,
    'currSessId': _currSessId,
  };

  /// Create Student object from Map
  factory Student.fromMap(Map<String, dynamic> map) => Student(
    id: map['id'],
    program: map['program'],
    studentId: map['studentId'],
    uId: map['uId'],
    sId: map['sId'],
    stdId: map['stdId'],
    stdName: map['stdName'],
    stdPhone: map['stdPhone'],
    stdEmail: map['stdEmail'],
    homePhone: map['homePhone'],
    stdReligion: map['stdReligion'],
    address: map['address'],
    dob: map['dob'],
    nidBirth: map['nidBirth'],
    country: map['country'],
    unionWord: map['unionWord'],
    fatherName: map['fatherName'],
    motherName: map['motherName'],
    fNid: map['fNid'],
    mNid: map['mNid'],
    gName: map['gName'],
    gAddress: map['gAddress'],
    gPhone: map['gPhone'],
    gEmail: map['gEmail'],
    stdImg: map['stdImg'],
    major: map['major'],
    sMajor: map['sMajor'],
    stdPass: map['stdPass'],
    gender: map['gender'],
    addDate: map['addDate'],
    aStatus: map['aStatus'],
    syncKey: map['syncKey'],
    syncStatus: map['syncStatus'] ?? 0,
    uniqueId: map['uniqueId'],
    currSessId: map['currSessId'],
  );

  /// Create a copy of the Student object with modifications
  Student copyWith({
    int? id,
    int? program,
    String? studentId,
    String? uId,
    String? sId,
    String? stdId,
    String? stdName,
    String? stdPhone,
    String? stdEmail,
    String? homePhone,
    String? stdReligion,
    String? address,
    String? dob,
    String? nidBirth,
    String? country,
    String? unionWord,
    String? fatherName,
    String? motherName,
    String? fNid,
    String? mNid,
    String? gName,
    String? gAddress,
    String? gPhone,
    String? gEmail,
    String? stdImg,
    String? major,
    String? sMajor,
    String? stdPass,
    String? gender,
    String? addDate,
    int? aStatus,
    String? syncKey,
    int? syncStatus,
    String? uniqueId,
    String? currSessId,
    String? imagePath,
    int? imageSyncStatus,
  }) =>
      Student(
        id: id ?? _id,
        program: program ?? _program,
        studentId: studentId ?? _studentId,
        uId: uId ?? _uId,
        sId: sId ?? _sId,
        stdId: stdId ?? _stdId,
        stdName: stdName ?? _stdName,
        stdPhone: stdPhone ?? _stdPhone,
        stdEmail: stdEmail ?? _stdEmail,
        homePhone: homePhone ?? _homePhone,
        stdReligion: stdReligion ?? _stdReligion,
        address: address ?? _address,
        dob: dob ?? _dob,
        nidBirth: nidBirth ?? _nidBirth,
        country: country ?? _country,
        unionWord: unionWord ?? _unionWord,
        fatherName: fatherName ?? _fatherName,
        motherName: motherName ?? _motherName,
        fNid: fNid ?? _fNid,
        mNid: mNid ?? _mNid,
        gName: gName ?? _gName,
        gAddress: gAddress ?? _gAddress,
        gPhone: gPhone ?? _gPhone,
        gEmail: gEmail ?? _gEmail,
        stdImg: stdImg ?? _stdImg,
        major: major ?? _major,
        sMajor: sMajor ?? _sMajor,
        stdPass: stdPass ?? _stdPass,
        gender: gender ?? _gender,
        addDate: addDate ?? _addDate,
        aStatus: aStatus ?? _aStatus,
        syncKey: syncKey ?? _syncKey,
        syncStatus: syncStatus ?? _syncStatus,
        uniqueId: uniqueId ?? _uniqueId,
        currSessId: currSessId ?? _currSessId,
        imagePath: imagePath ?? _imagePath,
        imageSyncStatus: imageSyncStatus ?? _imageSyncStatus,
      );

  /// Generate current admission date
  String generateAdmissionDate() {
    final now = DateTime.now();
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
  }

  @override
  String toString() => _stdName ?? '';
}





// import 'dart:typed_data';
// import 'package:intl/intl.dart';
//
// class Student {
//   int? id;
//   int? program;
//   String? studentId;
//   String? uId;
//   String? sId;
//   String? stdId;
//   String? stdName;
//   String? stdPhone;
//   String? stdEmail;
//   String? homePhone;
//   String? stdReligion;
//   String? address;
//   String? dob;
//   String? nidBirth;
//   String? country;
//   String? unionWord;
//   String? fatherName;
//   String? motherName;
//   String? fNid;
//   String? mNid;
//   String? gName;
//   String? gAddress;
//   String? gPhone;
//   String? gEmail;
//   String? stdImg;
//   String? major;
//   String? sMajor;
//   String? stdPass;
//   String? gender;
//   String? addDate;
//   int? aStatus;
//   Uint8List? imgData;
//   String? syncKey;
//   String? key;
//   int syncStatus = 0;
//   String? uniqueId;
//   String? currSessId;
//
//   /// Local image path (offline)
//   String? imagePath;
//
//   /// 0 = pending, 1 = synced
//   int imageSyncStatus;
//
//   // Constructor
//   Student({
//     this.id,
//     this.program,
//     this.studentId,
//     this.uId,
//     this.sId,
//     this.stdId,
//     this.stdName,
//     this.stdPhone,
//     this.stdEmail,
//     this.homePhone,
//     this.stdReligion,
//     this.address,
//     this.dob,
//     this.nidBirth,
//     this.country,
//     this.unionWord,
//     this.fatherName,
//     this.motherName,
//     this.fNid,
//     this.mNid,
//     this.gName,
//     this.gAddress,
//     this.gPhone,
//     this.gEmail,
//     this.stdImg,
//     this.major,
//     this.sMajor,
//     this.stdPass,
//     this.gender,
//     this.addDate,
//     this.aStatus,
//     this.imgData,
//     this.syncKey,
//     this.key,
//     this.syncStatus = 0,
//     this.uniqueId,
//     this.currSessId,
//     this.imagePath,
//     this.imageSyncStatus = 0,
//   });
//
//   // Getters and Setters
//   int? get getId => id;
//   set setId(int? id) => this.id = id;
//
//   int? get getProgram => program;
//   set setProgram(int? program) => this.program = program;
//
//   String? get getStudentId => studentId;
//   set setStudentId(String? studentId) => this.studentId = studentId;
//
//   String? get getUId => uId;
//   set setUId(String? uId) => this.uId = uId;
//
//   String? get getSId => sId;
//   set setSId(String? sId) => this.sId = sId;
//
//   String? get getStdId => stdId;
//   set setStdId(String? stdId) => this.stdId = stdId;
//
//   String? get getStdName => stdName;
//   set setStdName(String? stdName) => this.stdName = stdName;
//
//   String? get getStdPhone => stdPhone;
//   set setStdPhone(String? stdPhone) => this.stdPhone = stdPhone;
//
//   String? get getStdEmail => stdEmail;
//   set setStdEmail(String? stdEmail) => this.stdEmail = stdEmail;
//
//   String? get getHomePhone => homePhone;
//   set setHomePhone(String? homePhone) => this.homePhone = homePhone;
//
//   String? get getStdReligion => stdReligion;
//   set setStdReligion(String? stdReligion) => this.stdReligion = stdReligion;
//
//   String? get getAddress => address;
//   set setAddress(String? address) => this.address = address;
//
//   String? get getDob => dob;
//   set setDob(String? dob) => this.dob = dob;
//
//   String? get getNidBirth => nidBirth;
//   set setNidBirth(String? nidBirth) => this.nidBirth = nidBirth;
//
//   String? get getCountry => country;
//   set setCountry(String? country) => this.country = country;
//
//   String? get getUnionWord => unionWord;
//   set setUnionWord(String? unionWord) => this.unionWord = unionWord;
//
//   String? get getFatherName => fatherName;
//   set setFatherName(String? fatherName) => this.fatherName = fatherName;
//
//   String? get getMotherName => motherName;
//   set setMotherName(String? motherName) => this.motherName = motherName;
//
//   String? get getFNid => fNid;
//   set setFNid(String? fNid) => this.fNid = fNid;
//
//   String? get getMNid => mNid;
//   set setMNid(String? mNid) => this.mNid = mNid;
//
//   String? get getGName => gName;
//   set setGName(String? gName) => this.gName = gName;
//
//   String? get getGAddress => gAddress;
//   set setGAddress(String? gAddress) => this.gAddress = gAddress;
//
//   String? get getGPhone => gPhone;
//   set setGPhone(String? gPhone) => this.gPhone = gPhone;
//
//   String? get getGEmail => gEmail;
//   set setGEmail(String? gEmail) => this.gEmail = gEmail;
//
//   String? get getStdImg => stdImg;
//   set setStdImg(String? stdImg) => this.stdImg = stdImg;
//
//   String? get getMajor => major;
//   set setMajor(String? major) => this.major = major;
//
//   String? get getSMajor => sMajor;
//   set setSMajor(String? sMajor) => this.sMajor = sMajor;
//
//   String? get getStdPass => stdPass;
//   set setStdPass(String? stdPass) => this.stdPass = stdPass;
//
//   String? get getGender => gender;
//   set setGender(String? gender) => this.gender = gender;
//
//   String? get getAddDate => addDate;
//   set setAddDate(String? addDate) => this.addDate = addDate;
//
//   int? get getAStatus => aStatus;
//   set setAStatus(int? aStatus) => this.aStatus = aStatus;
//
//   Uint8List? get getImgData => imgData;
//   set setImgData(Uint8List? imgData) => this.imgData = imgData;
//
//   String? get getSyncKey => syncKey;
//   set setSyncKey(String? syncKey) => this.syncKey = syncKey;
//
//   int get getSyncStatus => syncStatus;
//   set setSyncStatus(int syncStatus) => this.syncStatus = syncStatus;
//
//   String? get getUniqueId => uniqueId;
//   set setUniqueId(String? uniqueId) => this.uniqueId = uniqueId;
//
//   String? get getCurrSessId => currSessId;
//   set setCurrSessId(String? currSessId) => this.currSessId = currSessId;
//
//   String? get getImagePath => imagePath;
//   set setImagePath(String? v) => imagePath = v;
//
//   int get getImageSyncStatus => imageSyncStatus;
//   set setImageSyncStatus(int v) => imageSyncStatus = v;
//
//
//   // Map to Object
//   Map<String, dynamic> toMap() {
//     return {
//       'id': id,
//       'program': program,
//       'studentId': studentId,
//       'uId': uId,
//       'sId': sId,
//       'stdId': stdId,
//       'stdName': stdName,
//       'stdPhone': stdPhone,
//       'stdEmail': stdEmail,
//       'homePhone': homePhone,
//       'stdReligion': stdReligion,
//       'address': address,
//       'dob': dob,
//       'nidBirth': nidBirth,
//       'country': country,
//       'unionWord': unionWord,
//       'fatherName': fatherName,
//       'motherName': motherName,
//       'fNid': fNid,
//       'mNid': mNid,
//       'gName': gName,
//       'gAddress': gAddress,
//       'gPhone': gPhone,
//       'gEmail': gEmail,
//       'stdImg': stdImg,
//       'major': major,
//       'sMajor': sMajor,
//       'stdPass': stdPass,
//       'gender': gender,
//       'addDate': addDate,
//       'aStatus': aStatus,
//       'imgData': imgData,
//       'syncKey': syncKey,
//       'syncStatus': syncStatus,
//       'uniqueId': uniqueId,
//       'currSessId': currSessId,
//     };
//   }
//
//   // Object from Map
//   static Student fromMap(Map<String, dynamic> map) {
//     return Student(
//       id: map['id'],
//       program: map['program'],
//       studentId: map['studentId'],
//       uId: map['uId'],
//       sId: map['sId'],
//       stdId: map['stdId'],
//       stdName: map['stdName'],
//       stdPhone: map['stdPhone'],
//       stdEmail: map['stdEmail'],
//       homePhone: map['homePhone'],
//       stdReligion: map['stdReligion'],
//       address: map['address'],
//       dob: map['dob'],
//       nidBirth: map['nidBirth'],
//       country: map['country'],
//       unionWord: map['unionWord'],
//       fatherName: map['fatherName'],
//       motherName: map['motherName'],
//       fNid: map['fNid'],
//       mNid: map['mNid'],
//       gName: map['gName'],
//       gAddress: map['gAddress'],
//       gPhone: map['gPhone'],
//       gEmail: map['gEmail'],
//       stdImg: map['stdImg'],
//       major: map['major'],
//       sMajor: map['sMajor'],
//       stdPass: map['stdPass'],
//       gender: map['gender'],
//       addDate: map['addDate'],
//       aStatus: map['aStatus'],
//       imgData: map['imgData'],
//       syncKey: map['syncKey'],
//       syncStatus: map['syncStatus'],
//       uniqueId: map['uniqueId'],
//       currSessId: map['currSessId'],
//     );
//   }
//
//   // Generate Admission Date
//   String generateAdmissionDate() {
//     DateTime now = DateTime.now();
//     DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
//     return formatter.format(now);
//   }
//
//   @override
//   String toString() {
//     return stdName ?? '';
//   }
// }
