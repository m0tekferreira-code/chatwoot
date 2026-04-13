<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import PipelineBoard from './PipelineBoard.vue';
import PipelineSettings from './PipelineSettings.vue';

const store = useStore();
const { t } = useI18n();
const { showAlert } = useAlert();

const showSettings = ref(false);
const showAddConversation = ref(false);
const conversationIdToAdd = ref('');

const pipelines = computed(() => store.getters['pipelines/getPipelines']);
const currentPipeline = computed(
  () => store.getters['pipelines/getCurrentPipeline']
);
const boardData = computed(() => store.getters['pipelines/getBoardData']);
const uiFlags = computed(() => store.getters['pipelines/getUIFlags']);

const selectedPipelineId = ref(null);

const selectPipeline = pipeline => {
  selectedPipelineId.value = pipeline.id;
  store.dispatch('pipelines/setCurrentPipeline', pipeline);
  store.dispatch('pipelines/fetchBoardData', pipeline.id);
};

const onMoveConversation = async ({ conversationId, stageId }) => {
  if (!currentPipeline.value) return;

  try {
    await store.dispatch('pipelines/moveConversation', {
      pipelineId: currentPipeline.value.id,
      conversationId,
      stageId,
    });
  } catch {
    showAlert(t('PIPELINE.BOARD.MOVE_ERROR'));
    store.dispatch('pipelines/fetchBoardData', currentPipeline.value.id);
  }
};

const addConversationToPipeline = async () => {
  if (!currentPipeline.value || !conversationIdToAdd.value) return;

  const defaultStage = boardData.value?.stages?.[0];
  if (!defaultStage) return;

  try {
    await store.dispatch('pipelines/addConversation', {
      pipelineId: currentPipeline.value.id,
      conversationId: Number(conversationIdToAdd.value),
      stageId: defaultStage.id,
    });
    conversationIdToAdd.value = '';
    showAddConversation.value = false;
    store.dispatch('pipelines/fetchBoardData', currentPipeline.value.id);
    showAlert(t('PIPELINE.BOARD.ADD_SUCCESS'));
  } catch {
    showAlert(t('PIPELINE.BOARD.ADD_ERROR'));
  }
};

const onSettingsSaved = () => {
  showSettings.value = false;
  store.dispatch('pipelines/get');
  if (currentPipeline.value) {
    store.dispatch('pipelines/fetchBoardData', currentPipeline.value.id);
  }
};

onMounted(() => {
  store.dispatch('pipelines/get');
});

watch(pipelines, newPipelines => {
  if (newPipelines.length && !selectedPipelineId.value) {
    selectPipeline(newPipelines[0]);
  }
});
</script>

<template>
  <div class="flex flex-col h-full bg-n-surface-2">
    <!-- Header -->
    <header class="flex items-center justify-between px-4 py-3 border-b border-n-weak bg-n-surface-1">
      <div class="flex items-center gap-3">
        <span class="i-lucide-kanban size-5 text-n-slate-12" />
        <h1 class="text-base font-semibold text-n-slate-12">
          {{ $t('PIPELINE.HEADER') }}
        </h1>

        <!-- Pipeline Selector -->
        <div
          v-if="pipelines.length"
          class="flex items-center gap-1 ml-2"
        >
          <button
            v-for="pipeline in pipelines"
            :key="pipeline.id"
            class="px-3 py-1.5 text-sm rounded-lg transition-colors"
            :class="
              selectedPipelineId === pipeline.id
                ? 'bg-n-brand text-white'
                : 'text-n-slate-11 hover:bg-n-alpha-2'
            "
            @click="selectPipeline(pipeline)"
          >
            {{ pipeline.name }}
          </button>
        </div>
      </div>

      <div class="flex items-center gap-2">
        <!-- Add Conversation -->
        <div
          v-if="currentPipeline && showAddConversation"
          class="flex items-center gap-2"
        >
          <input
            v-model="conversationIdToAdd"
            type="number"
            :placeholder="$t('PIPELINE.BOARD.CONVERSATION_ID_PLACEHOLDER')"
            class="px-3 py-1.5 text-sm border border-n-weak rounded-lg bg-n-surface-1 text-n-slate-12 w-40"
            @keyup.enter="addConversationToPipeline"
          />
          <button
            class="px-3 py-1.5 text-sm rounded-lg bg-n-brand text-white hover:bg-n-brand/90"
            @click="addConversationToPipeline"
          >
            {{ $t('PIPELINE.BOARD.ADD') }}
          </button>
          <button
            class="px-2 py-1.5 text-sm text-n-slate-11 hover:text-n-slate-12"
            @click="showAddConversation = false"
          >
            <span class="i-lucide-x size-4" />
          </button>
        </div>

        <button
          v-if="currentPipeline && !showAddConversation"
          class="flex items-center gap-1.5 px-3 py-1.5 text-sm rounded-lg text-n-slate-11 hover:bg-n-alpha-2"
          @click="showAddConversation = true"
        >
          <span class="i-lucide-plus size-4" />
          {{ $t('PIPELINE.BOARD.ADD_CONVERSATION') }}
        </button>

        <button
          class="flex items-center gap-1.5 px-3 py-1.5 text-sm rounded-lg text-n-slate-11 hover:bg-n-alpha-2"
          @click="showSettings = true"
        >
          <span class="i-lucide-settings size-4" />
          {{ $t('PIPELINE.SETTINGS.TITLE') }}
        </button>
      </div>
    </header>

    <!-- Board Content -->
    <PipelineBoard
      :board-data="boardData"
      :is-loading="uiFlags.isFetchingConversations"
      @move-conversation="onMoveConversation"
    />

    <!-- Settings Modal -->
    <PipelineSettings
      v-if="showSettings"
      :pipeline="currentPipeline"
      @close="showSettings = false"
      @saved="onSettingsSaved"
    />
  </div>
</template>
