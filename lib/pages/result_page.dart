import 'package:flutter/material.dart';
import 'package:test02/widgets/header.dart';
import 'package:test02/widgets/result_section.dart';
import 'package:test02/constants/exports.dart';

class ResultPage extends StatelessWidget {
  const ResultPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isMobile = AppSizes.isMobile(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            children: [
              // 헤더
              const Header(),
              SizedBox(height: AppSizes.getHeaderBottomPadding(context)),

              // 결과 섹션 (모든 기능을 포함)
              const ResultSection(),

              // 하단 여백
              SizedBox(height: AppSizes.getFooterPadding(context)),
            ],
          ),
        ),
      ),
    );
  }
}
