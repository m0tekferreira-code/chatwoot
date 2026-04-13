<script setup>
import { computed } from 'vue';
import PipelineColumn from './PipelineColumn.vue';

const props = defineProps({
  boardData: {
    type: Object,
    required: true,
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['move-conversation']);

const stages = computed(() => props.boardData?.stages || []);

const onDropConversation = ({ conversationId, stageId }) => {
  emit('move-conversation', { conversationId, stageId });
};
</script>

<template>
  <div class="flex-1 overflow-hidden">
    <!-- Loading State -->
    <div
      v-if="isLoading"
      class="flex items-center justify-center h-full"
    >
      <span class="i-lucide-loader-2 size-6 animate-spin text-n-brand" />
    </div>

    <!-- Board -->
    <div
      v-else-if="stages.length"
      class="flex gap-3 h-full overflow-x-auto p-4"
    >
      <PipelineColumn
        v-for="stage in stages"
        :key="stage.id"
        :stage="stage"
        @drop-conversation="onDropConversation"
      />
    </div>

    <!-- Empty State -->
    <div
      v-else
      class="flex flex-col items-center justify-center h-full gap-3"
    >
      <span class="i-lucide-columns-3 size-12 text-n-slate-8" />
      <p class="text-sm text-n-slate-11">
        {{ $t('PIPELINE.BOARD.EMPTY') }}
      </p>
    </div>
  </div>
</template>
