import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../bloc/learn_bloc.dart';
import '../bloc/learn_event.dart';
import '../bloc/learn_state.dart';
import '../widgets/feed_card.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LearnBloc()..add(const LearnFeedRequested()),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('Shared Strategies', style: AppTextStyles.titleLarge),
          centerTitle: false,
          backgroundColor: AppColors.surface,
          elevation: 0,
        ),
        body: BlocBuilder<LearnBloc, LearnState>(
          builder: (context, state) {
            if (state is LearnLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is LearnError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(state.message),
                    TextButton(
                      onPressed: () {
                        context
                            .read<LearnBloc>()
                            .add(const LearnFeedRequested());
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            } else if (state is LearnLoaded) {
              if (state.feed.isEmpty) {
                return const Center(child: Text("No strategies shared yet."));
              }
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<LearnBloc>().add(const LearnFeedRequested());
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.feed.length,
                  itemBuilder: (context, index) {
                    return FeedCard(item: state.feed[index]);
                  },
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
