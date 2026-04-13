<script setup>
import { computed } from 'vue';
import PipelineCard from './PipelineCard.vue';

const props = defineProps({
  stage: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['drop-conversation']);

const conversations = computed(() => props.stage.conversations || []);

const onDrop = event => {
  const conversationId = event.dataTransfer.getData('conversationId');
  if (conversationId) {
    emit('drop-conversation', {
      conversationId: Number(conversationId),
      stageId: props.stage.id,
    });
  }
};

const onDragOver = event => {
  event.preventDefault();
  event.dataTransfer.dropEffect = 'move';
};

const onDragStart = (event, conversation) => {
  event.dataTransfer.setData('conversationId', String(conversation.id));
  event.dataTransfer.effectAllowed = 'move';
};
</script>

<template>
  <div
    class="flex flex-col min-w-[280px] max-w-[320px] flex-1 rounded-xl bg-n-alpha-1 border border-n-weak"
    @dragover="onDragOver"
    @drop="onDrop"
  >
    <!-- Column Header -->
    <div class="flex items-center justify-between px-3 py-2.5 border-b border-n-weak">
      <div class="flex items-center gap-2 min-w-0">
        <span
          class="size-2.5 rounded-full shrink-0"
          :style="{ backgroundColor: stage.color }"
        />
        <h3 class="text-sm font-semibold text-n-slate-12 truncate">
          {{ stage.name }}
        </h3>
        <span
          class="inline-flex items-center justify-center rounded-full bg-n-alpha-2 px-1.5 py-0.5 text-xs font-medium text-n-slate-11"
        >
          {{ conversations.length }}
        </span>
      </div>
    </div>

    <!-- Cards Container -->
    <div class="flex-1 overflow-y-auto p-2 space-y-2 min-h-[120px]">
      <div
        v-for="conversation in conversations"
        :key="conversation.id"
        draggable="true"
        @dragstart="event => onDragStart(event, conversation)"
      >
        <PipelineCard :conversation="conversation" />
      </div>

      <div
        v-if="!conversations.length"
        class="flex items-center justify-center h-20 text-xs text-n-slate-10 italic"
      >
        {{ $t('PIPELINE.BOARD.EMPTY_STAGE') }}
      </div>
    </div>
  </div>
</template>
