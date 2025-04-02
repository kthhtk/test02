import 'package:flutter/material.dart';
import 'package:test02/widgets/select_section.dart';
import 'package:test02/constants/exports.dart';

class BestSection extends StatelessWidget {
  final Function(int)? onImageClick;
  final String? filter;

  const BestSection({Key? key, this.onImageClick, this.filter})
    : super(key: key);

  // 선택된 인덱스에 해당하는 이미지 경로 얻기
  String _getImagePathFromIndex(int index) {
    // 상수 클래스의 이미지 리스트 사용
    final List<String> modernImages = AppConstants.modernHanbokList;
    final List<String> traditionalImages = AppConstants.traditionalHanbokList;

    // 인덱스에 따라 이미지 경로 반환
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

  // 이미지 클릭 처리 함수
  void _handleImageClick(BuildContext context, int index) {
    // 외부에서 제공된 콜백이 있으면 그것을 사용
    if (onImageClick != null) {
      onImageClick!(index);
      return;
    }

    // 내부 처리 로직
    String imagePath = _getImagePathFromIndex(index);
    // 해당 이미지를 선택한 상태로 GeneratePage로 이동
    Navigator.pushNamed(
      context,
      AppConstants.generateRoute,
      arguments: imagePath, // 클릭한 이미지의 경로를 전달
    );
  }

  @override
  Widget build(BuildContext context) {
    // SelectSection을 사용하되, showFilterButtons를 false로 설정하여 필터 버튼을 숨김
    return SelectSection(
      onImageClick: (index) => _handleImageClick(context, index),
      showFilterButtons: false, // 필터 버튼 숨김
    );
  }
}
