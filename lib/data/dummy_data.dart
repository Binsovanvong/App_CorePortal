import '../models/request_model.dart';

class DummyData {
  static List<RequestModel> requests = [

    RequestModel(
      name: "Kao Satya",
      gender: "ប្រុស",
      idNumber: "5734524753",
      nationality: "Khmer Angkor",
      address: "ភ្នំពេញ",
      status: "Pending",
    ),

    RequestModel(
      name: "Sorn Sophy",
      gender: "ស្រី",
      idNumber: "4521109823",
      nationality: "ខ្មែរ",
      address: "សៀមរាប",
      status: "Approved",
    ),

    RequestModel(
      name: "Linda Smith",
      gender: "ស្រី",
      idNumber: "B88201243",
      nationality: "American",
      address: "USA",
      status: "Rejected",
    ),
  ];
}