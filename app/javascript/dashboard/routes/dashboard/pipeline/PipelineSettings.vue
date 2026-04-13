<script setup>
import { ref, computed, onMounted } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';

const props = defineProps({
  pipeline: {
    type: Object,
    default: null,
  },
});

const emit = defineEmits(['close', 'saved']);

const store = useStore();
const { t } = useI18n();
const { showAlert } = useAlert();

const activeTab = ref('pipelines');
const pipelineName = ref('');
const pipelineDescription = ref('');
const pipelineColor = ref('#1f93ff');

const editingPipeline = ref(null);
const stageName = ref('');
const stageColor = ref('#1f93ff');
const editingStage = ref(null);

const pipelines = computed(() => store.getters['pipelines/getPipelines']);
const uiFlags = computed(() => store.getters['pipelines/getUIFlags']);

const colors = [
  '#1f93ff', '#15803D', '#EAB308', '#F97316',
  '#EF4444', '#8B5CF6', '#EC4899', '#6B7280',
];

const resetPipelineForm = () => {
  pipelineName.value = '';
  pipelineDescription.value = '';
  pipelineColor.value = '#1f93ff';
  editingPipeline.value = null;
};

const resetStageForm = () => {
  stageName.value = '';
  stageColor.value = '#1f93ff';
  editingStage.value = null;
};

const createPipeline = async () => {
  if (!pipelineName.value.trim()) return;

  try {
    await store.dispatch('pipelines/create', {
      pipeline: {
        name: pipelineName.value,
        description: pipelineDescription.value,
        color: pipelineColor.value,
      },
    });
    showAlert(t('PIPELINE.SETTINGS.PIPELINE_CREATED'));
    resetPipelineForm();
    emit('saved');
  } catch {
    showAlert(t('PIPELINE.SETTINGS.PIPELINE_CREATE_ERROR'));
  }
};

const updatePipeline = async () => {
  if (!editingPipeline.value || !pipelineName.value.trim()) return;

  try {
    await store.dispatch('pipelines/update', {
      id: editingPipeline.value.id,
      pipeline: {
        name: pipelineName.value,
        description: pipelineDescription.value,
        color: pipelineColor.value,
      },
    });
    showAlert(t('PIPELINE.SETTINGS.PIPELINE_UPDATED'));
    resetPipelineForm();
    emit('saved');
  } catch {
    showAlert(t('PIPELINE.SETTINGS.PIPELINE_UPDATE_ERROR'));
  }
};

const deletePipeline = async pipeline => {
  try {
    await store.dispatch('pipelines/delete', pipeline.id);
    showAlert(t('PIPELINE.SETTINGS.PIPELINE_DELETED'));
    emit('saved');
  } catch {
    showAlert(t('PIPELINE.SETTINGS.PIPELINE_DELETE_ERROR'));
  }
};

const editPipeline = pipeline => {
  editingPipeline.value = pipeline;
  pipelineName.value = pipeline.name;
  pipelineDescription.value = pipeline.description || '';
  pipelineColor.value = pipeline.color || '#1f93ff';
};

const createStage = async () => {
  if (!props.pipeline || !stageName.value.trim()) return;

  try {
    await store.dispatch('pipelines/createStage', {
      pipelineId: props.pipeline.id,
      stageObj: {
        stage: {
          name: stageName.value,
          color: stageColor.value,
          position: props.pipeline.stages?.length || 0,
        },
      },
    });
    showAlert(t('PIPELINE.SETTINGS.STAGE_CREATED'));
    resetStageForm();
    emit('saved');
  } catch {
    showAlert(t('PIPELINE.SETTINGS.STAGE_CREATE_ERROR'));
  }
};

const updateStage = async () => {
  if (!props.pipeline || !editingStage.value) return;

  try {
    await store.dispatch('pipelines/updateStage', {
      pipelineId: props.pipeline.id,
      stageId: editingStage.value.id,
      stageObj: {
        stage: {
          name: stageName.value,
          color: stageColor.value,
        },
      },
    });
    showAlert(t('PIPELINE.SETTINGS.STAGE_UPDATED'));
    resetStageForm();
    emit('saved');
  } catch {
    showAlert(t('PIPELINE.SETTINGS.STAGE_UPDATE_ERROR'));
  }
};

const deleteStage = async stage => {
  if (!props.pipeline) return;

  try {
    await store.dispatch('pipelines/deleteStage', {
      pipelineId: props.pipeline.id,
      stageId: stage.id,
    });
    showAlert(t('PIPELINE.SETTINGS.STAGE_DELETED'));
    emit('saved');
  } catch {
    showAlert(t('PIPELINE.SETTINGS.STAGE_DELETE_ERROR'));
  }
};

const editStage = stage => {
  editingStage.value = stage;
  stageName.value = stage.name;
  stageColor.value = stage.color || '#1f93ff';
};

onMounted(() => {
  store.dispatch('pipelines/get');
});
</script>

<template>
  <div class="fixed inset-0 z-50 flex items-center justify-center bg-n-alpha-4">
    <div class="w-full max-w-2xl mx-4 rounded-xl bg-n-surface-1 shadow-xl border border-n-weak overflow-hidden">
      <!-- Modal Header -->
      <div class="flex items-center justify-between px-6 py-4 border-b border-n-weak">
        <h2 class="text-lg font-semibold text-n-slate-12">
          {{ $t('PIPELINE.SETTINGS.TITLE') }}
        </h2>
        <button
          class="text-n-slate-11 hover:text-n-slate-12"
          @click="$emit('close')"
        >
          <span class="i-lucide-x size-5" />
        </button>
      </div>

      <!-- Tabs -->
      <div class="flex border-b border-n-weak px-6">
        <button
          class="px-4 py-2.5 text-sm font-medium border-b-2 transition-colors"
          :class="
            activeTab === 'pipelines'
              ? 'border-n-brand text-n-brand'
              : 'border-transparent text-n-slate-11 hover:text-n-slate-12'
          "
          @click="activeTab = 'pipelines'"
        >
          {{ $t('PIPELINE.SETTINGS.TAB_PIPELINES') }}
        </button>
        <button
          v-if="pipeline"
          class="px-4 py-2.5 text-sm font-medium border-b-2 transition-colors"
          :class="
            activeTab === 'stages'
              ? 'border-n-brand text-n-brand'
              : 'border-transparent text-n-slate-11 hover:text-n-slate-12'
          "
          @click="activeTab = 'stages'"
        >
          {{ $t('PIPELINE.SETTINGS.TAB_STAGES') }}
        </button>
      </div>

      <!-- Content -->
      <div class="p-6 max-h-[60vh] overflow-y-auto">
        <!-- Pipelines Tab -->
        <div v-if="activeTab === 'pipelines'">
          <!-- Create/Edit Form -->
          <div class="flex flex-col gap-3 mb-6">
            <div class="flex gap-3">
              <input
                v-model="pipelineName"
                type="text"
                :placeholder="$t('PIPELINE.SETTINGS.PIPELINE_NAME_PLACEHOLDER')"
                class="flex-1 px-3 py-2 text-sm border border-n-weak rounded-lg bg-n-surface-1 text-n-slate-12"
              />
              <div class="flex gap-1">
                <button
                  v-for="c in colors"
                  :key="c"
                  class="size-8 rounded-lg border-2 transition-colors"
                  :class="
                    pipelineColor === c
                      ? 'border-n-slate-12'
                      : 'border-transparent'
                  "
                  :style="{ backgroundColor: c }"
                  @click="pipelineColor = c"
                />
              </div>
            </div>
            <input
              v-model="pipelineDescription"
              type="text"
              :placeholder="$t('PIPELINE.SETTINGS.PIPELINE_DESC_PLACEHOLDER')"
              class="px-3 py-2 text-sm border border-n-weak rounded-lg bg-n-surface-1 text-n-slate-12"
            />
            <div class="flex gap-2">
              <button
                class="px-4 py-2 text-sm rounded-lg bg-n-brand text-white hover:bg-n-brand/90"
                :disabled="uiFlags.isCreating || uiFlags.isUpdating"
                @click="editingPipeline ? updatePipeline() : createPipeline()"
              >
                {{
                  editingPipeline
                    ? $t('PIPELINE.SETTINGS.UPDATE_PIPELINE')
                    : $t('PIPELINE.SETTINGS.CREATE_PIPELINE')
                }}
              </button>
              <button
                v-if="editingPipeline"
                class="px-4 py-2 text-sm rounded-lg text-n-slate-11 hover:bg-n-alpha-2"
                @click="resetPipelineForm"
              >
                {{ $t('PIPELINE.SETTINGS.CANCEL') }}
              </button>
            </div>
          </div>

          <!-- Pipelines List -->
          <div class="space-y-2">
            <div
              v-for="p in pipelines"
              :key="p.id"
              class="flex items-center justify-between p-3 rounded-lg border border-n-weak"
            >
              <div class="flex items-center gap-3">
                <span
                  class="size-4 rounded-full shrink-0"
                  :style="{ backgroundColor: p.color }"
                />
                <div>
                  <p class="text-sm font-medium text-n-slate-12">
                    {{ p.name }}
                  </p>
                  <p
                    v-if="p.description"
                    class="text-xs text-n-slate-11"
                  >
                    {{ p.description }}
                  </p>
                </div>
              </div>
              <div class="flex items-center gap-1">
                <button
                  class="p-1.5 rounded-lg text-n-slate-11 hover:text-n-slate-12 hover:bg-n-alpha-2"
                  @click="editPipeline(p)"
                >
                  <span class="i-lucide-pencil size-4" />
                </button>
                <button
                  class="p-1.5 rounded-lg text-n-slate-11 hover:text-n-ruby-9 hover:bg-n-alpha-2"
                  @click="deletePipeline(p)"
                >
                  <span class="i-lucide-trash-2 size-4" />
                </button>
              </div>
            </div>
          </div>
        </div>

        <!-- Stages Tab -->
        <div v-if="activeTab === 'stages' && pipeline">
          <!-- Create/Edit Stage Form -->
          <div class="flex flex-col gap-3 mb-6">
            <div class="flex gap-3">
              <input
                v-model="stageName"
                type="text"
                :placeholder="$t('PIPELINE.SETTINGS.STAGE_NAME_PLACEHOLDER')"
                class="flex-1 px-3 py-2 text-sm border border-n-weak rounded-lg bg-n-surface-1 text-n-slate-12"
              />
              <div class="flex gap-1">
                <button
                  v-for="c in colors"
                  :key="c"
                  class="size-8 rounded-lg border-2 transition-colors"
                  :class="
                    stageColor === c
                      ? 'border-n-slate-12'
                      : 'border-transparent'
                  "
                  :style="{ backgroundColor: c }"
                  @click="stageColor = c"
                />
              </div>
            </div>
            <div class="flex gap-2">
              <button
                class="px-4 py-2 text-sm rounded-lg bg-n-brand text-white hover:bg-n-brand/90"
                @click="editingStage ? updateStage() : createStage()"
              >
                {{
                  editingStage
                    ? $t('PIPELINE.SETTINGS.UPDATE_STAGE')
                    : $t('PIPELINE.SETTINGS.CREATE_STAGE')
                }}
              </button>
              <button
                v-if="editingStage"
                class="px-4 py-2 text-sm rounded-lg text-n-slate-11 hover:bg-n-alpha-2"
                @click="resetStageForm"
              >
                {{ $t('PIPELINE.SETTINGS.CANCEL') }}
              </button>
            </div>
          </div>

          <!-- Stages List -->
          <div class="space-y-2">
            <div
              v-for="stage in pipeline.stages"
              :key="stage.id"
              class="flex items-center justify-between p-3 rounded-lg border border-n-weak"
            >
              <div class="flex items-center gap-3">
                <span
                  class="size-4 rounded-full shrink-0"
                  :style="{ backgroundColor: stage.color }"
                />
                <div>
                  <p class="text-sm font-medium text-n-slate-12">
                    {{ stage.name }}
                  </p>
                  <p class="text-xs text-n-slate-11">
                    {{ stage.conversations_count || 0 }}
                    {{ $t('PIPELINE.SETTINGS.CONVERSATIONS') }}
                  </p>
                </div>
              </div>
              <div class="flex items-center gap-1">
                <button
                  class="p-1.5 rounded-lg text-n-slate-11 hover:text-n-slate-12 hover:bg-n-alpha-2"
                  @click="editStage(stage)"
                >
                  <span class="i-lucide-pencil size-4" />
                </button>
                <button
                  class="p-1.5 rounded-lg text-n-slate-11 hover:text-n-ruby-9 hover:bg-n-alpha-2"
                  @click="deleteStage(stage)"
                >
                  <span class="i-lucide-trash-2 size-4" />
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Footer -->
      <div class="flex justify-end px-6 py-4 border-t border-n-weak">
        <button
          class="px-4 py-2 text-sm rounded-lg text-n-slate-11 hover:bg-n-alpha-2"
          @click="$emit('close')"
        >
          {{ $t('PIPELINE.SETTINGS.CLOSE') }}
        </button>
      </div>
    </div>
  </div>
</template>
