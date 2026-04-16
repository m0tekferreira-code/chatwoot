<script setup>
import { computed, onMounted, ref } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';

const props = defineProps({
  conversationId: {
    type: [Number, String],
    required: true,
  },
});

const store = useStore();
const { t } = useI18n();
const showAlert = useAlert;

const selectedPipelineId = ref(null);
const selectedStageId = ref(null);

const pipelines = computed(() => store.getters['pipelines/getPipelines']);
const uiFlags = computed(() => store.getters['pipelines/getUIFlags']);

const currentChat = computed(() => store.getters['getSelectedChat']);

// Check if conversation is in a pipeline
const pipelineInfo = computed(() => {
  // This would ideally come from the conversation metadata
  return currentChat.value?.pipeline_info || null;
});

const stages = computed(() => {
  if (!selectedPipelineId.value) return [];
  const pipeline = pipelines.value.find(p => p.id === selectedPipelineId.value);
  return pipeline?.stages || [];
});

onMounted(async () => {
  await store.dispatch('pipelines/get');
  if (pipelineInfo.value) {
    selectedPipelineId.value = pipelineInfo.value.pipeline_id;
    selectedStageId.value = pipelineInfo.value.pipeline_stage_id;
  }
});

const addToPipeline = async () => {
  if (!selectedPipelineId.value || !selectedStageId.value) return;

  try {
    await store.dispatch('pipelines/addConversation', {
      pipelineId: selectedPipelineId.value,
      conversationId: props.conversationId,
      stageId: selectedStageId.value,
    });
    showAlert(t('PIPELINE.BOARD.ADD_SUCCESS'));
    // Refetch conversation to update pipeline_info
    store.dispatch('getConversation', props.conversationId);
  } catch {
    showAlert(t('PIPELINE.BOARD.ADD_ERROR'));
  }
};
</script>

<template>
  <div class="p-4 bg-n-surface-1 rounded-lg border border-n-weak space-y-4">
    <div v-if="pipelines.length" class="space-y-3">
      <!-- Pipeline Selection -->
      <div class="space-y-1.5">
        <label class="text-xs font-semibold text-n-slate-11 uppercase">
          Pipeline
        </label>
        <select
          v-model="selectedPipelineId"
          class="w-full px-3 py-1.5 text-sm border border-n-weak rounded-lg bg-n-surface-1 text-n-slate-12 outline-none focus:border-n-brand"
        >
          <option :value="null" disabled>Selecionar Pipeline</option>
          <option v-for="p in pipelines" :key="p.id" :value="p.id">
            {{ p.name }}
          </option>
        </select>
      </div>

      <!-- Stage Selection -->
      <div v-if="selectedPipelineId" class="space-y-1.5">
        <label class="text-xs font-semibold text-n-slate-11 uppercase">
          Estágio
        </label>
        <select
          v-model="selectedStageId"
          class="w-full px-3 py-1.5 text-sm border border-n-weak rounded-lg bg-n-surface-1 text-n-slate-12 outline-none focus:border-n-brand"
        >
          <option :value="null" disabled>Selecionar Estágio</option>
          <option v-for="s in stages" :key="s.id" :value="s.id">
            {{ s.name }}
          </option>
        </select>
      </div>

      <button
        class="w-full px-4 py-2 text-sm font-medium rounded-lg bg-n-brand text-white hover:bg-n-brand/90 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
        :disabled="!selectedStageId || uiFlags.isMovingConversation"
        @click="addToPipeline"
      >
        {{ pipelineInfo ? 'Mudar de Estágio' : 'Adicionar ao Pipeline' }}
      </button>
    </div>
    <div v-else class="text-center py-4">
      <p class="text-sm text-n-slate-11">
        Nenhum pipeline disponível.
      </p>
    </div>
  </div>
</template>
