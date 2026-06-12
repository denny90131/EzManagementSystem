import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../Services/Authenticator/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _isLoading = false; // 加入載入狀態
  final _formKey = GlobalKey<FormState>();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // 註冊專用必填欄位
  final TextEditingController companyController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController jobTitleController = TextEditingController();
  final TextEditingController emergencyContactController = TextEditingController();
  final TextEditingController emergencyContactPhoneController = TextEditingController();
  String? _selectedEmergencyContactRel;

  // 註冊專用選填欄位
  final TextEditingController medicalHistoryController = TextEditingController();
  String? _selectedGender;
  String? _selectedBloodType;
  final TextEditingController birthdayController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  // 註冊專用 FocusNodes
  final FocusNode _companyFocusNode = FocusNode();
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _jobTitleFocusNode = FocusNode();
  final FocusNode _emergencyContactFocusNode = FocusNode();
  final FocusNode _emergencyContactPhoneFocusNode = FocusNode();
  final FocusNode _medicalHistoryFocusNode = FocusNode();
  final FocusNode _birthdayFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _addressFocusNode = FocusNode();
  final FocusNode _relFocusNode = FocusNode();
  final FocusNode _genderFocusNode = FocusNode();
  final FocusNode _bloodFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final nodes = [
      _companyFocusNode, _nameFocusNode, _phoneFocusNode, _passwordFocusNode,
      _jobTitleFocusNode, _emergencyContactFocusNode, _emergencyContactPhoneFocusNode,
      _medicalHistoryFocusNode, _birthdayFocusNode, _emailFocusNode, _addressFocusNode,
      _relFocusNode, _genderFocusNode, _bloodFocusNode
    ];
    for (var node in nodes) {
      node.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    final nodes = [
      _companyFocusNode, _nameFocusNode, _phoneFocusNode, _passwordFocusNode,
      _jobTitleFocusNode, _emergencyContactFocusNode, _emergencyContactPhoneFocusNode,
      _medicalHistoryFocusNode, _birthdayFocusNode, _emailFocusNode, _addressFocusNode,
      _relFocusNode, _genderFocusNode, _bloodFocusNode
    ];
    for (var node in nodes) {
      node.dispose();
    }
    // 釋放所有 controller 資源
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('無法存取相機或相簿，請確認裝置是否支援且已給予權限。')),
      );
    }
  }

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
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined, color: Color(0xFFE5BA73)),
                title: const Text('拍照', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _submit() async {
    // 觸發驗證，如果所有 isRequired 的欄位都有填寫，才會進入首頁
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // 按下按鈕時開始轉圈圈
      });
      
        // ========== 執行註冊 API 呼叫 ==========
        try {
          String? base64Image;
          // 如果有選擇照片，將其轉換為 Base64 字串
          if (_selectedImage != null) {
            final bytes = await _selectedImage!.readAsBytes();
            base64Image = base64Encode(bytes);
          }

          // 建立符合 API 規格的 Payload
          final Map<String, dynamic> payload = {
            "name": nameController.text.trim(),
            "password": passwordController.text.trim(),
            "phoneNumber": phoneController.text.trim(),
            "company": companyController.text.trim().isEmpty ? null : companyController.text.trim(),
            "position": jobTitleController.text.trim().isEmpty ? null : jobTitleController.text.trim(),
            "iceName": emergencyContactController.text.trim().isEmpty ? null : emergencyContactController.text.trim(),
            "icePhoneNumber": emergencyContactPhoneController.text.trim().isEmpty ? null : emergencyContactPhoneController.text.trim(),
            "iceRelation": _selectedEmergencyContactRel,
            "geneticHistory": medicalHistoryController.text.trim().isEmpty ? null : medicalHistoryController.text.trim(),
            "blood": _selectedBloodType,
            "gender": _selectedGender,
            "birth": birthdayController.text.trim().isEmpty ? null : "${birthdayController.text.trim()}T00:00:00",
            "email": emailController.text.trim().isEmpty ? null : emailController.text.trim(),
            "address": addressController.text.trim().isEmpty ? null : addressController.text.trim(),
            "picture": base64Image,
          };

          // 呼叫獨立出來的 ApiService
          final errorMessage = await ApiService.registerUser(payload);

          if (!mounted) return;

          if (errorMessage == null) {
            // 註冊成功，顯示提示並返回登入畫面
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('註冊成功！')));
            // 註冊成功後，返回登入頁面
            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('註冊失敗：$errorMessage')));
          }
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('發生未預期的錯誤：$e')));
        } finally {
          if (mounted) {
            setState(() {
              _isLoading = false; // 恢復按鈕狀態
            });
          }
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121824), // 深底色
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('註冊帳號', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE5BA73), letterSpacing: 2)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFE5BA73)),
      ),
      body: Stack(
        children: [
          // 金色微光渲染層
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.2,
                  colors: [
                    const Color(0xFFE5BA73).withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // 全螢幕背景圖紋
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: const AssetImage('assets/images/pattern_bg.png'),
                  fit: BoxFit.cover,
                  opacity: 0.15,
                  onError: (exception, stackTrace) {
                    // 找不到圖片時靜默忽略，避免整個註冊畫面崩潰
                  },
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                // 頂端大頭貼 (點擊上傳/更換照片)
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
                          backgroundImage: _selectedImage != null ? FileImage(_selectedImage!) : null,
                          child: _selectedImage == null
                          ? const Icon(Icons.person_outline, size: 50, color: Color(0xFFE5BA73))
                              : null,
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFE5BA73), Color(0xFFC19A5B)],
                            ),
                            shape: BoxShape.circle
                          ),
                          child: const Icon(Icons.camera_alt_outlined, color: Colors.black, size: 20),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                          _buildTextField(nameController, '姓名', icon: Icons.person_outline, isRequired: true, focusNode: _nameFocusNode),
                          _buildTextField(phoneController, '手機', icon: Icons.phone_outlined, keyboardType: TextInputType.phone, isRequired: true, focusNode: _phoneFocusNode),
                          _buildTextField(passwordController, '密碼', icon: Icons.lock_outline, obscureText: true, isRequired: true, focusNode: _passwordFocusNode),
                          _buildTextField(companyController, '公司名稱', icon: Icons.business_outlined, focusNode: _companyFocusNode),
                          _buildTextField(jobTitleController, '職務', icon: Icons.work_outline, focusNode: _jobTitleFocusNode),
                          _buildTextField(emergencyContactController, '緊急聯絡人', icon: Icons.contact_emergency_outlined, focusNode: _emergencyContactFocusNode),
                          _buildTextField(emergencyContactPhoneController, '緊急聯絡人手機', icon: Icons.phone_in_talk_outlined, keyboardType: TextInputType.phone, focusNode: _emergencyContactPhoneFocusNode),
                          _buildDropdownField(
                            label: '聯絡人關係',
                            value: _selectedEmergencyContactRel,
                            items: ['父母', '配偶', '子女', '兄弟姊妹', '朋友'],
                            icon: Icons.people_outline,
                            focusNode: _relFocusNode,
                            onChanged: (val) {
                              setState(() {
                                _selectedEmergencyContactRel = val;
                              });
                            },
                          ),
                          const Divider(height: 32, color: Colors.white12), // 分隔線
                          _buildTextField(medicalHistoryController, '遺傳病史', icon: Icons.medical_services_outlined, focusNode: _medicalHistoryFocusNode),
                          _buildDropdownField(
                            label: '性別',
                            value: _selectedGender,
                            items: ['男', '女'],
                            icon: Icons.wc_outlined,
                            focusNode: _genderFocusNode,
                            onChanged: (val) {
                              setState(() {
                                _selectedGender = val;
                              });
                            },
                          ),
                          _buildDropdownField(
                            label: '血型',
                            value: _selectedBloodType,
                            items: ['A', 'B', 'O', 'AB'],
                            icon: Icons.bloodtype_outlined,
                            focusNode: _bloodFocusNode,
                            onChanged: (val) {
                              setState(() {
                                _selectedBloodType = val;
                              });
                            },
                          ),
                          _buildTextField(
                            birthdayController,
                            '生日',
                            icon: Icons.cake_outlined,
                            readOnly: true,
                            focusNode: _birthdayFocusNode,
                            onTap: () => _selectDate(context),
                          ),
                          _buildTextField(emailController, '聯絡信箱', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress, focusNode: _emailFocusNode),
                          _buildTextField(addressController, '聯絡地址', icon: Icons.home_work_outlined, focusNode: _addressFocusNode),
                          
                          const SizedBox(height: 24),
                          Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE5BA73), Color(0xFFC19A5B)], // 金色漸層
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(color: const Color(0xFFE5BA73).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submit, // 讀取中停用按鈕防連點
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.black, // 黑字
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _isLoading
                                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                                  : const Text('註冊', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context); // 點擊返回登入頁
                            },
                            child: const Text('已有帳號？點此登入', style: TextStyle(color: Color(0xFFE5BA73), fontWeight: FontWeight.bold, letterSpacing: 1)),
                          )
                        ],
                      ),
                ),
              ],
            ),
          ),
        ),
        ),
      ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    IconData? icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
    bool isRequired = false,
    FocusNode? focusNode,
  }) {
    final bool isFocused = focusNode?.hasFocus ?? false;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            if (isFocused)
              BoxShadow(
                color: const Color(0xFFE5BA73).withOpacity(0.2),
                blurRadius: 16,
                spreadRadius: 1,
              ),
          ],
        ),
        child: TextFormField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          style: const TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.w500, fontSize: 16),
          validator: (value) {
            if (isRequired && (value == null || value.trim().isEmpty)) {
              return '請輸入$label';
            }
            if (value != null && value.trim().isNotEmpty && keyboardType == TextInputType.emailAddress) {
              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
              if (!emailRegex.hasMatch(value)) {
                return '請輸入有效的信箱格式';
              }
            }
            return null;
          },
          decoration: InputDecoration(
            label: Text.rich(
              TextSpan(
                text: label,
                children: [
                  if (isRequired)
                    const TextSpan(text: ' *', style: TextStyle(color: Color(0xFFE5BA73))),
                ],
              ),
              style: TextStyle(color: isFocused ? const Color(0xFFE5BA73) : const Color(0xFF8A94A6)),
            ),
            prefixIcon: icon != null ? Icon(icon, color: isFocused ? const Color(0xFFE5BA73) : const Color(0xFF8A94A6)) : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5BA73), width: 1.5),
            ),
            filled: true,
            fillColor: const Color(0xFF1A2232), // 不透明卡片底色
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required List<String> items,
    required String? value,
    required ValueChanged<String?> onChanged,
    IconData? icon,
    bool isRequired = false,
    FocusNode? focusNode,
  }) {
    final bool isFocused = focusNode?.hasFocus ?? false;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            if (isFocused)
              BoxShadow(
                color: const Color(0xFFE5BA73).withOpacity(0.2),
                blurRadius: 16,
                spreadRadius: 1,
              ),
          ],
        ),
        child: DropdownButtonFormField<String>(
          value: value,
          focusNode: focusNode,
          onChanged: onChanged,
          dropdownColor: const Color(0xFF1A2232), // 下拉選單卡片底色
          style: const TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.w500, fontSize: 16),
          validator: isRequired
              ? (val) => (val == null || val.trim().isEmpty) ? '請選擇$label' : null
              : null,
          decoration: InputDecoration(
            label: Text.rich(
              TextSpan(
                text: label,
                children: [
                  if (isRequired)
                    const TextSpan(text: ' *', style: TextStyle(color: Color(0xFFE5BA73))),
                ],
              ),
              style: TextStyle(color: isFocused ? const Color(0xFFE5BA73) : const Color(0xFF8A94A6)),
            ),
            prefixIcon: icon != null ? Icon(icon, color: isFocused ? const Color(0xFFE5BA73) : const Color(0xFF8A94A6)) : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5BA73), width: 1.5),
            ),
            filled: true,
            fillColor: const Color(0xFF1A2232), // 不透明卡片底色
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
        ),
      ),
    );
  }
}