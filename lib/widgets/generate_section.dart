import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'dart:math' as math;
// dart:io는 웹에서 지원되지 않으므로 조건부 import
// ignore: avoid_web_libraries_in_flutter
import 'dart:io' if (dart.library.html) 'dart:ui' as ui;
import 'package:test02/constants/exports.dart';
import 'package:test02/widgets/select_section.dart';

// 점선 원 그리는 커스텀 페인터
class DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gapSize;
  final double dashSize;

  DashedCirclePainter({
    required this.color,
    required this.strokeWidth,
    required this.gapSize,
    required this.dashSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke;

    // 원의 중심과 반지름 계산
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    // 원 둘레 계산
    final circumference = 2 * math.pi * radius;

    // 각 점선 호의 각도 계산
    final dashAngle = (dashSize / circumference) * 2 * math.pi;
    final gapAngle = (gapSize / circumference) * 2 * math.pi;

    // 시작 각도
    double startAngle = 0;

    // 원을 따라 점선 그리기
    while (startAngle < 2 * math.pi) {
      // 현재 각도에서 dash 길이만큼 호 그리기
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashAngle,
        false,
        paint,
      );

      // 다음 dash의 시작 위치로 이동
      startAngle += dashAngle + gapAngle;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class GenerateSection extends StatefulWidget {
  // 외부에서 선택된 한복 이미지를 받을 수 있도록 속성 추가
  final String? selectedHanbokImage;
  // 패딩 적용 여부 (페이지에서 직접 사용할 때는 true, 다른 위젯에 포함될 때는 false)
  final bool usePadding;
  // 외부 스크롤 컨트롤러 추가
  final ScrollController? externalScrollController;

  const GenerateSection({
    Key? key,
    this.selectedHanbokImage,
    this.usePadding = false,
    this.externalScrollController,
  }) : super(key: key);

  @override
  State<GenerateSection> createState() => _GenerateSectionState();
}

class _GenerateSectionState extends State<GenerateSection> {
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();

  // 한복 프리셋 이미지 경로 목록
  final List<String> _hanbokPresets = [
    'assets/images/modern/modern_001.png',
    'assets/images/modern/modern_002.png',
    'assets/images/traditional/traditional_001.png',
    'assets/images/traditional/traditional_002.png',
    'assets/images/traditional/traditional_003.png',
  ];

  // 선택된 한복 이미지
  String? _selectedHanbokImage;

  // 현재 활성화된 필터
  String? _currentFilter;

  // 내부 스크롤 컨트롤러
  final ScrollController _internalScrollController = ScrollController();

  // 사용할 스크롤 컨트롤러 얻기
  ScrollController get _scrollController =>
      widget.externalScrollController ?? _internalScrollController;

  @override
  void initState() {
    super.initState();
    // 외부에서 전달된 이미지가 있으면 설정
    if (widget.selectedHanbokImage != null) {
      _selectedHanbokImage = widget.selectedHanbokImage;
    }
  }

  @override
  void didUpdateWidget(GenerateSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 속성이 변경되었을 때 상태 업데이트
    if (widget.selectedHanbokImage != null &&
        widget.selectedHanbokImage != oldWidget.selectedHanbokImage) {
      setState(() {
        _selectedHanbokImage = widget.selectedHanbokImage;
      });
    }
  }

  @override
  void dispose() {
    // 내부 컨트롤러만 해제 (외부는 외부에서 관리)
    if (widget.externalScrollController == null) {
      _internalScrollController.dispose();
    }
    super.dispose();
  }

  // 이미지가 선택되었을 때 호출되는 함수
  void _onImageSelected(String imagePath) {
    setState(() {
      _selectedHanbokImage = imagePath;
    });

    // 최상단으로 스크롤
    _scrollToTop();
  }

  // 최상단으로 스크롤
  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: AppConstants.pageTransitionDuration,
        curve: Curves.easeInOut,
      );
    }
  }

  // SelectSection을 위한 스크롤 메서드
  void scrollToTop() {
    _scrollToTop();
  }

  // 재배열된 이미지 목록에서 정확한 이미지 경로 가져오기
  String _getImagePathFromIndex(int index, {String? filter}) {
    // 상수 클래스의 이미지 리스트 사용
    final List<String> modernImages = AppConstants.modernHanbokList;
    final List<String> traditionalImages = AppConstants.traditionalHanbokList;

    // 필터가 적용된 경우
    if (filter == AppConstants.filterModern) {
      // Modern 필터 - 인덱스가 modernImages 범위 내에 있으면 해당 이미지 반환
      if (index < modernImages.length) {
        return modernImages[index];
      }
      return modernImages[0]; // 기본값
    } else if (filter == AppConstants.filterTraditional) {
      // Traditional 필터 - 인덱스가 traditionalImages 범위 내에 있으면 해당 이미지 반환
      if (index < traditionalImages.length) {
        return traditionalImages[index];
      }
      return traditionalImages[0]; // 기본값
    }

    // 필터가 없는 경우 (전체 이미지 보기)
    // 2장씩 배치 로직에 맞춘 인덱스 계산
    int row = index ~/ 4; // 몇 번째 줄인지 계산
    int col = index % 4; // 줄 내 위치 (0,1: 모던, 2,3: 트래디셔널)

    if (col < 2) {
      // 모던 이미지 (0,1번 열)
      int modernIndex = row * 2 + col;
      if (modernIndex < modernImages.length) {
        return modernImages[modernIndex];
      }
    } else {
      // 트래디셔널 이미지 (2,3번 열)
      int traditionalIndex = row * 2 + (col - 2);
      if (traditionalIndex < traditionalImages.length) {
        return traditionalImages[traditionalIndex];
      }
    }

    // 기본값으로 첫 번째 이미지 반환
    return modernImages[0];
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 90,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      // 에러 처리
      debugPrint('Error picking image: $e');
      // 사용자에게 오류 메시지 표시
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('이미지를 선택하는 중 오류가 발생했습니다: $e')));
      }
    }
  }

  // 한복 이미지 선택 함수
  void _selectHanbokImage(String imagePath) {
    setState(() {
      _selectedHanbokImage = imagePath;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = AppSizes.isMobile(context);
    bool isTablet = AppSizes.isTablet(context);

    // 모바일과 태블릿에서는 세로로 배치, 데스크탑에서는 가로로 배치
    Widget mainContent =
        isMobile || isTablet
            ? _buildMobileTabletContent(context)
            : _buildDesktopContent(context);

    // 전체 위젯
    Widget content = SingleChildScrollView(
      controller: _scrollController,
      physics: const ClampingScrollPhysics(),
      child: Column(
        children: [
          // 상단 한복 선택 및 업로드 섹션
          Container(
            width: double.infinity,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                mainContent,

                // Constants/exports.dart에 정의된 반응형 패딩 사용
                SizedBox(height: AppSizes.getTryOnButtonTopPadding(context)),

                // Try On button
                StatefulBuilder(
                  builder: (context, setState) {
                    bool isHovered = false;
                    bool isMobile = AppSizes.isMobile(context);
                    bool isTablet = AppSizes.isTablet(context);

                    return MouseRegion(
                      onEnter: (_) => setState(() => isHovered = true),
                      onExit: (_) => setState(() => isHovered = false),
                      child: AnimatedContainer(
                        duration: AppConstants.defaultAnimationDuration,
                        width: AppSizes.getButtonWidth(context),
                        height: AppSizes.getButtonHeight(context),
                        decoration: BoxDecoration(
                          color:
                              isHovered
                                  ? AppColors.buttonHover
                                  : AppColors.background,
                          borderRadius: BorderRadius.circular(
                            AppConstants.defaultButtonBorderRadius,
                          ),
                          border: Border.all(
                            color:
                                isHovered
                                    ? AppColors.primary
                                    : AppColors.border,
                            width:
                                isHovered
                                    ? AppConstants.borderWidthThick
                                    : AppConstants.borderWidthThin,
                          ),
                          boxShadow:
                              isHovered
                                  ? [
                                    BoxShadow(
                                      color: AppColors.shadowColor,
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                  : null,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(
                              AppConstants.defaultButtonBorderRadius,
                            ),
                            onTap: () {
                              // 양쪽 이미지가 모두 선택되었는지 확인
                              if (_imageBytes != null &&
                                  _selectedHanbokImage != null) {
                                Navigator.pushNamed(
                                  context,
                                  AppConstants.resultRoute,
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('사용자 이미지와 한복 이미지를 모두 선택해주세요'),
                                  ),
                                );
                              }
                            },
                            child: Center(
                              child: Text(
                                'Try On',
                                style: AppTextStyles.button(context).copyWith(
                                  color:
                                      isHovered
                                          ? AppColors.textButton
                                          : AppColors.textPrimary,
                                  fontWeight:
                                      isHovered
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                  fontSize:
                                      isMobile ? 14 : (isTablet ? 16 : null),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // 한복 선택 섹션
          SizedBox(height: AppSizes.getSection1BottomPadding(context)),

          // SelectSection 통합
          Padding(
            padding: AppSizes.getScreenPadding(context),
            child: SelectSection(
              onImageClick: (index) {
                // 필터 상태도 함께 전달
                String imagePath = _getImagePathFromIndex(
                  index,
                  filter: _currentFilter,
                );
                _onImageSelected(imagePath);

                // 최상단으로 스크롤
                _scrollToTop();
              },
              onFilterChange: (filter) {
                // 필터가 변경될 때 호출되는 콜백
                setState(() {
                  _currentFilter = filter;
                });
              },
              parentScrollController: _scrollController,
            ),
          ),
        ],
      ),
    );

    // usePadding이 true인 경우 패딩 적용
    if (widget.usePadding) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32),
        child: content,
      );
    }

    return content;
  }

  // 데스크탑 레이아웃 (좌: 업로드 버튼, 중앙: 한복 이미지, 우: 프리셋)
  Widget _buildDesktopContent(BuildContext context) {
    final presetSize = AppSizes.getPresetImageSize(context);
    // 프리셋 5개의 높이 + 간격(20px * 4개) 계산
    final totalPresetHeight = (presetSize * 5) + (20 * 4);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Upload button (왼쪽)
          _buildUploadButton(context),

          const SizedBox(width: 20),

          // 중앙 - 한복 이미지 디스플레이
          Expanded(
            child: Container(
              height: totalPresetHeight, // 프리셋 높이와 일치
              decoration: BoxDecoration(
                color: AppColors.backgroundMedium,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border, width: 0.2),
              ),
              child:
                  _selectedHanbokImage == null
                      ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '+',
                              style: TextStyle(
                                fontSize: 48,
                                color: Color(0xFFAAAAAA),
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              '한복을 선택해주세요',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFFAAAAAA),
                              ),
                            ),
                          ],
                        ),
                      )
                      : ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          _selectedHanbokImage!,
                          fit: BoxFit.contain,
                          height: totalPresetHeight,
                          alignment: Alignment.center,
                        ),
                      ),
            ),
          ),

          const SizedBox(width: 20),

          // Hanbok presets (오른쪽)
          Column(
            children: [
              for (int i = 0; i < _hanbokPresets.length; i++) ...[
                _buildPresetButton(context, _hanbokPresets[i]),
                if (i < _hanbokPresets.length - 1) const SizedBox(height: 20),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // 모바일 및 태블릿 레이아웃 (이미지 컨테이너 내부에 업로드 버튼 위치)
  Widget _buildMobileTabletContent(BuildContext context) {
    bool isMobile = AppSizes.isMobile(context);
    bool isTablet = AppSizes.isTablet(context);
    final buttonSize = AppSizes.getUploadButtonSize(context);

    // 데스크탑 레이아웃에서 사용하는 프리셋 높이 계산 (참조용)
    final presetSize = AppSizes.getPresetImageSize(context);
    final totalPresetHeightDesktop = (presetSize * 5) + (20 * 4);

    // 타블렛은 데스크탑보다 50px 작게, 모바일은 더 작게 설정
    final containerHeight =
        isMobile ? 270.0 : (totalPresetHeightDesktop - 50.0);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 10 : 20,
        vertical: isMobile ? 15 : 25,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // 이미지 컨테이너 (upload 버튼이 내부에 포함됨)
          Container(
            width: double.infinity,
            height: containerHeight,
            decoration: BoxDecoration(
              color: AppColors.backgroundMedium,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border, width: 0.2),
            ),
            child: Stack(
              children: [
                // 한복 이미지
                _selectedHanbokImage == null
                    ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '+',
                            style: TextStyle(
                              fontSize: 48,
                              color: Color(0xFFAAAAAA),
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            '한복을 선택해주세요',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFFAAAAAA),
                            ),
                          ),
                        ],
                      ),
                    )
                    : ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Center(
                        child: Image.asset(
                          _selectedHanbokImage!,
                          fit: BoxFit.contain,
                          height: containerHeight,
                          alignment: Alignment.center,
                        ),
                      ),
                    ),

                // 업로드 버튼을 좌측 상단에 위치
                Positioned(
                  top: 15, // 상단 패딩
                  left: 15, // 좌측 패딩
                  child: _buildUploadButton(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 하단 부분: 프리셋 그리드 (5개)
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              for (int i = 0; i < _hanbokPresets.length; i++)
                _buildPresetButton(context, _hanbokPresets[i]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUploadButton(BuildContext context) {
    // 반응형 크기 적용
    final buttonSize = AppSizes.getUploadButtonSize(context);
    // isMobile 추가
    bool isMobile = AppSizes.isMobile(context);

    return InkWell(
      onTap: _pickImage,
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.background,
          // 실선 테두리 제거
        ),
        child:
            _imageBytes != null
                ? ClipOval(child: Image.memory(_imageBytes!, fit: BoxFit.cover))
                : Stack(
                  alignment: Alignment.center,
                  children: [
                    // 점선 테두리를 위한 CustomPaint
                    CustomPaint(
                      size: Size(buttonSize, buttonSize),
                      painter: DashedCirclePainter(
                        color: AppColors.border,
                        strokeWidth: 1.5,
                        gapSize: 5.0,
                        dashSize: 5.0,
                      ),
                    ),
                    // 아이콘과 텍스트를 수직으로 배치
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 기존의 + 아이콘 (크기 축소)
                        Icon(
                          Icons.add,
                          size: buttonSize * 0.25, // 크기 축소
                          color: AppColors.textSecondary,
                        ),
                        // 간격 축소 (5px → 2px)
                        SizedBox(height: 2),
                        // your image 텍스트 크기 더 작게 설정
                        Text(
                          'your image',
                          style: TextStyle(
                            fontSize: isMobile ? 8 : 10, // 모바일에서는 더 작게
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildPresetButton(BuildContext context, String imagePath) {
    final bool isSelected = _selectedHanbokImage == imagePath;
    // 반응형 크기 적용
    final presetSize = AppSizes.getPresetImageSize(context);

    // 외부 컨테이너 (외부 테두리)의 모서리 둥글기
    final double outerRadius = AppConstants.defaultCardBorderRadius;
    // 내부 이미지 컨테이너의 모서리 둥글기 (선택 시 약간 줄어듦)
    final double innerRadius =
        isSelected ? 5 : AppConstants.defaultCardBorderRadius;

    return StatefulBuilder(
      builder: (context, setState) {
        bool isHovered = false;

        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: InkWell(
            onTap: () => _selectHanbokImage(imagePath),
            child: AnimatedContainer(
              duration: AppConstants.defaultAnimationDuration,
              width: presetSize,
              height: presetSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(outerRadius),
                border: Border.all(
                  color:
                      isSelected
                          ? AppColors.imageStrokeHover
                          : (isHovered
                              ? AppColors.primary
                              : AppColors.border.withOpacity(0.1)),
                  width:
                      isSelected || isHovered
                          ? AppConstants.borderWidthThick
                          : AppConstants.borderWidthThin,
                ),
                boxShadow:
                    isHovered
                        ? [
                          BoxShadow(
                            color: AppColors.shadowColor,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                        : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(innerRadius),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
