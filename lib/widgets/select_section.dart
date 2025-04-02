import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'dart:math' as math;
import 'package:test02/constants/exports.dart';

class SelectSection extends StatefulWidget {
  // 이미지 클릭 이벤트 핸들러
  final Function(int) onImageClick;
  // 필터 변경 이벤트 핸들러
  final Function(String?)? onFilterChange;
  // 필터 버튼 표시 여부
  final bool showFilterButtons; // 필터 버튼 표시 여부 (자식 BestSection에서 false로 설정)
  // 상위 컴포넌트의 스크롤 컨트롤러
  final ScrollController? parentScrollController;

  const SelectSection({
    Key? key,
    required this.onImageClick,
    this.onFilterChange,
    this.showFilterButtons = true, // 기본값은 표시함
    this.parentScrollController,
  }) : super(key: key);

  @override
  State<SelectSection> createState() => _SelectSectionState();
}

class _SelectSectionState extends State<SelectSection> {
  String? activeFilter;

  // 롤오버 상태를 위한 맵 (인덱스를 키로 사용)
  final Map<int, bool> hoverStates = {};
  // 필터 버튼 롤오버 상태
  final Map<String, bool> filterHoverStates = {};

  // 더보기 버튼 상태
  bool showMoreImages = false;
  // 롤오버 상태
  bool isMoreButtonHovered = false;

  // 이미지 리스트는 AppConstants에서 가져오기
  final List<String> modernImageList = AppConstants.modernHanbokList;
  final List<String> traditionalImageList = AppConstants.traditionalHanbokList;

  final List<int> clickCounts = List.filled(16, 0); // 클릭 카운트

  // 스크롤 컨트롤러 추가
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 스크롤 컨트롤러 초기화 - PrimaryScrollController를 직접 사용
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 컨텍스트가 있는지 확인
      if (mounted) {
        // _scrollController.attach(PrimaryScrollController.of(context)); // 잘못된 방식
        // 대신 값을 모니터링하고 필요할 때 사용
        _scrollController.addListener(() {
          // 스크롤 이벤트 발생 시 처리 (필요한 경우)
        });
      }
    });
  }

  @override
  void dispose() {
    // 스크롤 컨트롤러 해제
    _scrollController.dispose();
    super.dispose();
  }

  // 최상단으로 스크롤
  void _scrollToTop() {
    // 부모 컴포넌트의 스크롤 컨트롤러가 있으면 사용
    if (widget.parentScrollController != null &&
        widget.parentScrollController!.hasClients) {
      widget.parentScrollController!.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      return;
    }

    // 부모 컨트롤러가 없으면 PrimaryScrollController 사용
    final scrollController = PrimaryScrollController.of(context);
    if (scrollController.hasClients) {
      scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  // 필터링된 이미지 목록 반환
  List<String> getFilteredImages() {
    if (activeFilter == AppConstants.filterModern) {
      return modernImageList;
    } else if (activeFilter == AppConstants.filterTraditional) {
      return traditionalImageList;
    } else {
      // 모든 이미지 (모던 + 전통)
      return [...modernImageList, ...traditionalImageList];
    }
  }

  List<int> _getSortedIndices() {
    final filteredImages = getFilteredImages();
    return List.generate(filteredImages.length, (index) => index);
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = AppSizes.isMobile(context);
    bool isTablet = AppSizes.isTablet(context);
    bool isDesktop = AppSizes.isDesktop(context);

    return Column(
      children: [
        // Filter buttons - showFilterButtons가 true일 때만 표시
        if (widget.showFilterButtons)
          Padding(
            padding: EdgeInsets.only(
              bottom: 20, // AppSizes.getSectionSpacing(context) / 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildFilterButton(AppConstants.filterModern),
                const SizedBox(width: 40),
                _buildFilterButton(AppConstants.filterTraditional),
              ],
            ),
          ),

        // 이미지 그리드 섹션
        _buildImageGridSection(context),
      ],
    );
  }

  Widget _buildFilterButton(String filterName) {
    final bool isActive = activeFilter == filterName;
    final bool isHovered = filterHoverStates[filterName] == true;

    return MouseRegion(
      onEnter: (_) {
        setState(() {
          filterHoverStates[filterName] = true;
        });
      },
      onExit: (_) {
        setState(() {
          filterHoverStates[filterName] = false;
        });
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(
            AppConstants.defaultButtonBorderRadius,
          ),
          onTap: () {
            setState(() {
              activeFilter = isActive ? null : filterName;

              // 필터 변경 시 더보기 상태 초기화
              showMoreImages = false;

              // 필터 변경 콜백 호출
              if (widget.onFilterChange != null) {
                widget.onFilterChange!(activeFilter);
              }
            });
          },
          child: Container(
            width: AppConstants.filterButtonWidth,
            height: AppConstants.filterButtonHeight,
            decoration: BoxDecoration(
              color:
                  isHovered && !isActive
                      ? AppColors.backgroundLight
                      : AppColors.background,
              borderRadius: BorderRadius.circular(
                AppConstants.defaultButtonBorderRadius,
              ),
              border: Border.all(
                color: isActive ? const Color(0xFF6E6E6E) : AppColors.border,
                width:
                    isActive
                        ? AppConstants.borderWidthThick
                        : AppConstants.borderWidthMedium,
              ),
            ),
            child: Center(
              child: Text(
                filterName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 이미지 그리드 섹션 (기존 BestSection의 주요 기능)
  Widget _buildImageGridSection(BuildContext context) {
    bool isMobile = AppSizes.isMobile(context);
    bool isTablet = AppSizes.isTablet(context);
    bool isDesktop = AppSizes.isDesktop(context);

    // 화면 크기에 따라 컬럼 수 설정
    int crossAxisCount;
    if (isMobile) {
      crossAxisCount = 2; // 모바일: 2개
    } else if (isTablet) {
      crossAxisCount = 3; // 태블릿: 3개
    } else {
      crossAxisCount = 4; // 데스크탑: 4개
    }

    List<int> sortedIndices = _getSortedIndices();
    var filteredImages = getFilteredImages();

    // 필터링되지 않은 경우(전체 이미지)만 모던/트래디셔널 이미지 재배열
    if (activeFilter == null) {
      // 모던 이미지와 트래디셔널 이미지를 번갈아 배치 (한 줄에 모던 2장, 트래디셔널 2장)
      List<String> arrangedImages = [];

      // 각 이미지 타입별로 지정된 수만큼 번갈아가며 추가
      // 한 줄에 모던 2장, 트래디셔널 2장씩 배치
      for (
        int i = 0;
        i < math.max(modernImageList.length, traditionalImageList.length);
        i += 2
      ) {
        // 모던 이미지 2장 추가
        for (int j = 0; j < 2; j++) {
          int modernIndex = i + j;
          if (modernIndex < modernImageList.length) {
            arrangedImages.add(modernImageList[modernIndex]);
          }
        }

        // 트래디셔널 이미지 2장 추가
        for (int j = 0; j < 2; j++) {
          int traditionalIndex = i + j;
          if (traditionalIndex < traditionalImageList.length) {
            arrangedImages.add(traditionalImageList[traditionalIndex]);
          }
        }
      }

      sortedIndices = List.generate(arrangedImages.length, (index) => index);
      filteredImages = arrangedImages;
    }

    return Column(
      children: [
        MasonryGridView.count(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          itemCount: showMoreImages ? filteredImages.length : 8,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            bottom: AppSizes.getSection1BottomPadding(context) * 0.5,
          ), // 하단 패딩 줄임
          itemBuilder: (context, index) {
            final imageIndex = sortedIndices[index % sortedIndices.length];
            final bool isSmallImage =
                imageIndex % 3 == 1; // Every third image is smaller

            // 롤오버 효과 상태 확인
            final bool isHovered = hoverStates[imageIndex] == true;

            // 이미지 사전 로드 (깜빡임 방지)
            precacheImage(
              AssetImage(filteredImages[imageIndex % filteredImages.length]),
              context,
            );

            // 주어진 이미지 경로
            final String imagePath =
                filteredImages[imageIndex % filteredImages.length];

            // 외부 컨테이너 (외부 테두리)의 모서리 둥글기
            final double outerRadius = AppConstants.defaultCardBorderRadius;
            // 내부 이미지 컨테이너의 모서리 둥글기 (롤오버/선택 시 약간 줄어듦)
            final double innerRadius =
                isHovered ? 11 : AppConstants.defaultCardBorderRadius;

            return MouseRegion(
              onEnter: (_) {
                setState(() {
                  hoverStates[imageIndex] = true;
                });
              },
              onExit: (_) {
                setState(() {
                  hoverStates[imageIndex] = false;
                });
              },
              child: RepaintBoundary(
                // 성능 최적화
                child: GestureDetector(
                  onTap: () {
                    // 클릭 카운트 증가
                    setState(() {
                      clickCounts[imageIndex]++;
                    });

                    // 이미지 클릭 핸들러 호출
                    widget.onImageClick(imageIndex);

                    // 페이지 최상단으로 스크롤
                    _scrollToTop();
                  },
                  child: AspectRatio(
                    aspectRatio: isSmallImage ? 0.8 : 0.7, // 가로세로 비율 설정
                    child: AnimatedContainer(
                      duration: AppConstants.defaultAnimationDuration,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(outerRadius),
                        border: Border.all(
                          color:
                              isHovered
                                  ? AppColors
                                      .imageStrokeHover // 원래 색상으로 복원
                                  : AppColors.border.withOpacity(0.3),
                          width:
                              isHovered
                                  ? AppConstants
                                      .borderWidthHover // 원래 두께로 복원
                                  : AppConstants.borderWidthThin,
                        ),
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
                ),
              ),
            );
          },
        ),

        // 버튼 간격
        const SizedBox(height: 20),

        // "More Images" 버튼 - 항상 표시
        if (!showMoreImages)
          MouseRegion(
            onEnter: (_) {
              setState(() {
                isMoreButtonHovered = true;
              });
            },
            onExit: (_) {
              setState(() {
                isMoreButtonHovered = false;
              });
            },
            child: AnimatedContainer(
              duration: AppConstants.defaultAnimationDuration,
              width: AppConstants.moreButtonWidth,
              height: AppConstants.moreButtonHeight,
              decoration: BoxDecoration(
                color:
                    isMoreButtonHovered
                        ? AppColors.backgroundLight
                        : AppColors.background,
                borderRadius: BorderRadius.circular(
                  AppConstants.defaultButtonBorderRadius,
                ),
                border: Border.all(
                  color: AppColors.border,
                  width: AppConstants.borderWidthMedium,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(
                    AppConstants.defaultButtonBorderRadius,
                  ),
                  onTap: () {
                    setState(() {
                      showMoreImages = true;
                    });
                  },
                  child: Center(
                    child: Text(
                      "More Images",
                      style: AppTextStyles.body2(context),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
