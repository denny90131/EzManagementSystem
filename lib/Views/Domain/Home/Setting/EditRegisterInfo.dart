import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../Services/Authenticator/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const EditProfileScreen({super.key, this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  String? _originalPassword = "********"; // 用於表示原始密碼未更改的佔位符
  bool _isLoading = false;
  bool _isSaving = false;
  String? _userId;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController(); // 密碼改為選填，留空代表不更改

  final TextEditingController companyController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController jobTitleController = TextEditingController();
  final TextEditingController emergencyContactController = TextEditingController();
  final TextEditingController emergencyContactPhoneController = TextEditingController();
  String? _selectedEmergencyContactRel;

  final TextEditingController medicalHistoryController = TextEditingController();
  String? _selectedGender;
  String? _selectedBloodType;
  final TextEditingController birthdayController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker(); // 新增 ImagePicker 實例
  String? _originalPictureBase64; // 儲存從後端載入的原始圖片 Base64
  bool _isImageCleared = false; // 追蹤使用者是否明確清除了圖片

  @override
  void initState() {
    super.initState();
    if (widget.userData != null) {
      _userId = widget.userData!['index']?.toString() ?? 
                widget.userData!['Index']?.toString();
      _populateData(widget.userData!);
    }
    _loadUserData();
  }

  void _populateData(Map<String, dynamic> userData) {
    nameController.text = userData['name'] ?? '';
    companyController.text = userData['company'] ?? '';
    phoneController.text = userData['phoneNumber'] ?? '';
    jobTitleController.text = userData['position'] ?? '';
    emergencyContactController.text = userData['iceName'] ?? '';
    emergencyContactPhoneController.text = userData['icePhoneNumber'] ?? '';
    
    // 確保回傳的值在選單中，避免 Dropdown 報錯
    final validRels = ['父母', '配偶', '子女', '兄弟姊妹', '朋友'];
    if (validRels.contains(userData['iceRelation'])) _selectedEmergencyContactRel = userData['iceRelation'];

    medicalHistoryController.text = userData['geneticHistory'] ?? '';
    if (['男', '女'].contains(userData['gender'])) _selectedGender = userData['gender'];
    if (['A', 'B', 'O', 'AB'].contains(userData['blood'])) _selectedBloodType = userData['blood'];
    
    if (userData['birth'] != null && userData['birth'].toString().contains('T')) {
      birthdayController.text = userData['birth'].toString().split('T')[0];
    }
    emailController.text = userData['email'] ?? '';
    addressController.text = userData['address'] ?? '';
  }

  Future<void> _loadUserData() async {
    if (widget.userData == null) {
      setState(() => _isLoading = true);
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      _userId ??= prefs.getString('user_id');

      if (_userId != null) {
        final userData = await ApiService.getUserById(_userId!);
        if (userData != null) {
          setState(() {
            _populateData(userData);
          });
        }
      }
    } catch (e) {
      // 背景更新失敗也沒關係，因為我們已經從首頁拿到了大部分資料
    } finally {
      if (widget.userData == null) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    phoneController.dispose();
    passwordController.dispose();
    companyController.dispose();
    nameController.dispose();
    jobTitleController.dispose();
    emergencyContactController.dispose();
    emergencyContactPhoneController.dispose();
    medicalHistoryController.dispose();
    birthdayController.dispose();
    emailController.dispose();
    addressController.dispose();
    super.dispose();
  }

  // 選擇圖片來源 (相機或相簿)
  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _isImageCleared = false; // 選擇新圖片後，清除狀態設為 false
      });
    }
  }

  // 顯示圖片來源選擇的 ActionSheet
  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A2232), // 卡片底色
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: Color(0xFFE5BA73)),
                title: const Text('從相簿選擇', style: TextStyle(color: Colors.white)),
                onTap: () { Navigator.of(context).pop(); _pickImage(ImageSource.gallery); },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined, color: Color(0xFFE5BA73)),
                title: const Text('拍照', style: TextStyle(color: Colors.white)),
                onTap: () { Navigator.of(context).pop(); _pickImage(ImageSource.camera); },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    // 1. 先確認表單有無紅字驗證錯誤
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('請檢查是否有必填欄位未填或格式錯誤')));
      return;
    }

    // 2. 確認是否有抓到 UserID
    if (_userId == null || _userId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('無法取得使用者 ID，請嘗試重新登入')));
      // 印出目前收到的所有欄位名稱，方便找出真正的 ID 叫什麼
      final keys = widget.userData?.keys.join(', ') ?? '無資料';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('找不到 UserID (後端傳來的欄位有: $keys)\n請聯絡開發者或重新登入')));
      return;
    }

    setState(() => _isSaving = true);
    
    try {
      String? base64Image;
      if (_selectedImage != null) {
        final bytes = await _selectedImage!.readAsBytes();
        base64Image = base64Encode(bytes);
      } else if (_isImageCleared) {
        base64Image = null; // 使用者明確清除了圖片
      } else {
        base64Image = _originalPictureBase64; // 沒有新選擇，也沒有清除，則保留原始圖片
      }

      // 3. 建立 Payload，並確保沒填寫的欄位傳送空字串 (避免 400 Bad Request)
      final Map<String, dynamic> payload = {
        "index": _userId, // 根據 API 規格，主鍵欄位應為 index
        "name": nameController.text.trim(),
        "phoneNumber": phoneController.text.trim(),
        "company": companyController.text.trim(),
        "position": jobTitleController.text.trim(),
        "iceName": emergencyContactController.text.trim(),
        "icePhoneNumber": emergencyContactPhoneController.text.trim(),
        "iceRelation": _selectedEmergencyContactRel ?? "",
        "geneticHistory": medicalHistoryController.text.trim(),
        "blood": _selectedBloodType ?? "",
        "gender": _selectedGender ?? "",
        "birth": birthdayController.text.trim().isEmpty ? "1900-01-01T00:00:00" : "${birthdayController.text.trim()}T00:00:00",
        "email": emailController.text.trim(),
        "address": addressController.text.trim(),
      };

      // 密碼欄位處理：如果有輸入新密碼就用新的；沒輸入就把舊密碼原封不動傳回去；若都沒有則傳空字串
      payload["password"] = passwordController.text.trim().isNotEmpty 
          ? passwordController.text.trim() 
          : (_originalPassword ?? "");

      payload["picture"] = base64Image; // 圖片處理
      final errorMessage = await ApiService.updateUser(payload);

      if (!mounted) return;

      if (errorMessage == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('資料更新成功！'),duration: Duration(seconds: 1))); // 加上這一行，設定顯示時間為 2 秒));
        Navigator.pop(context); // 儲存成功後返回首頁
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('更新失敗：$errorMessage')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('發生錯誤：$e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        birthdayController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Widget _buildTextField(TextEditingController controller, String label, {IconData? icon, bool obscureText = false, TextInputType? keyboardType, bool readOnly = false, VoidCallback? onTap, bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 16),
        validator: (value) {
          if (isRequired && (value == null || value.trim().isEmpty)) return '請輸入$label';
          return null;
        },
        decoration: InputDecoration(
          label: Text.rich(TextSpan(text: label, children: [if (isRequired) const TextSpan(text: ' *', style: TextStyle(color: Color(0xFFE5BA73)))])),
          labelStyle: const TextStyle(color: Color(0xFF8A94A6)),
          prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF8A94A6)) : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE5BA73), width: 1.5)),
          filled: true,
          fillColor: const Color(0xFF1A2232), // 深藍灰卡片質感
        ),
      ),
    );
  }

  Widget _buildDropdownField({required String label, required List<String> items, required String? value, required ValueChanged<String?> onChanged, IconData? icon, bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<String>(
        value: value,
        onChanged: onChanged,
        dropdownColor: const Color(0xFF1A2232),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 16),
        validator: isRequired ? (val) => (val == null || val.trim().isEmpty) ? '請選擇$label' : null : null,
        decoration: InputDecoration(
          label: Text.rich(TextSpan(text: label, children: [if (isRequired) const TextSpan(text: ' *', style: TextStyle(color: Color(0xFFE5BA73)))])),
          labelStyle: const TextStyle(color: Color(0xFF8A94A6)),
          prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF8A94A6)) : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE5BA73), width: 1.5)),
          filled: true,
          fillColor: const Color(0xFF1A2232),
        ),
        items: items.map((String item) => DropdownMenuItem<String>(value: item, child: Text(item))).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121824), // 深底色
      appBar: AppBar(
        title: const Text('編輯個人資料', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color(0xFF121824), // 深底色
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              // 大頭貼上傳區塊
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: const Color(0xFFE5BA73).withOpacity(0.15), blurRadius: 16, spreadRadius: 2),
                      ],
                    ),
                    child: GestureDetector(
                      onTap: () => _showImageSourceActionSheet(context),
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: const Color(0xFF1A2232),
                            backgroundImage: _selectedImage != null
                                ? FileImage(_selectedImage!)
                                : (_originalPictureBase64 != null && _originalPictureBase64!.isNotEmpty && !_isImageCleared
                                    // 確保去除可能帶有的前綴與所有空白、換行，避免白屏崩潰
                                    ? MemoryImage(base64Decode(_originalPictureBase64!.split(',').last.replaceAll(RegExp(r'\s+'), '')))
                                    : null),
                            child: (_selectedImage == null && (_originalPictureBase64 == null || _originalPictureBase64!.isEmpty || _isImageCleared))
                                ? const Icon(Icons.person_outline, size: 50, color: Color(0xFFE5BA73))
                                : null,
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFE5BA73), Color(0xFFC19A5B)],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt_outlined, color: Colors.black, size: 20),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_selectedImage != null || (_originalPictureBase64 != null && !_isImageCleared))
                    TextButton(onPressed: () { setState(() { _selectedImage = null; _isImageCleared = true; }); }, child: const Text('清除照片', style: TextStyle(color: Colors.redAccent))),
                  const SizedBox(height: 32),
                  
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                    _buildTextField(companyController, '公司名稱', icon: Icons.business),
                    _buildTextField(nameController, '姓名', icon: Icons.person, isRequired: true),
                    _buildTextField(phoneController, '手機', icon: Icons.phone, keyboardType: TextInputType.phone, isRequired: true),
                    
                    // 密碼變為選填
                    _buildTextField(passwordController, '修改密碼 (若不更改請留空)', icon: Icons.lock, obscureText: true),
                    
                    _buildTextField(jobTitleController, '職務', icon: Icons.work),
                    _buildTextField(emergencyContactController, '緊急聯絡人', icon: Icons.contact_emergency),
                    _buildTextField(emergencyContactPhoneController, '緊急聯絡人手機', icon: Icons.phone_in_talk, keyboardType: TextInputType.phone),
                    _buildDropdownField(
                      label: '聯絡人關係',
                      value: _selectedEmergencyContactRel,
                      items: ['父母', '配偶', '子女', '兄弟姊妹', '朋友'],
                      icon: Icons.people,
                      onChanged: (val) => setState(() => _selectedEmergencyContactRel = val),
                    ),
                    const Divider(height: 32, color: Colors.white12),
                    _buildTextField(medicalHistoryController, '遺傳病史', icon: Icons.medical_services),
                    _buildDropdownField(
                      label: '性別',
                      value: _selectedGender,
                      items: ['男', '女'],
                      icon: Icons.wc,
                      onChanged: (val) => setState(() => _selectedGender = val),
                    ),
                    _buildDropdownField(
                      label: '血型',
                      value: _selectedBloodType,
                      items: ['A', 'B', 'O', 'AB'],
                      icon: Icons.bloodtype,
                      onChanged: (val) => setState(() => _selectedBloodType = val),
                    ),
                    _buildTextField(birthdayController, '生日', icon: Icons.cake, readOnly: true, onTap: () => _selectDate(context)),
                    _buildTextField(emailController, '聯絡信箱', icon: Icons.email, keyboardType: TextInputType.emailAddress),
                    _buildTextField(addressController, '聯絡地址', icon: Icons.home_work),
                    
                    const SizedBox(height: 40),
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE5BA73), Color(0xFFC19A5B)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFFE5BA73).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSaving
                            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                            : const Text('儲存變更', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}