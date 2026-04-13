<script setup>
import { computed } from 'vue';
import { useRouter } from 'vue-router';
import { useAccount } from 'dashboard/composables/useAccount';

const props = defineProps({
  conversation: {
    type: Object,
    required: true,
  },
});

const router = useRouter();
const { accountScopedRoute } = useAccount();

const contactName = computed(
  () => props.conversation.contact?.name || 'Unknown'
);

const contactInitial = computed(() => {
  return contactName.value.charAt(0).toUpperCase();
});

const assigneeName = computed(
  () => props.conversation.assignee?.name || null
);

const statusColor = computed(() => {
  const colors = {
    open: 'bg-n-amber-9',
    resolved: 'bg-n-teal-9',
    pending: 'bg-n-blue-9',
    snoozed: 'bg-n-slate-9',
  };
  return colors[props.conversation.status] || 'bg-n-slate-9';
});

const priorityIcon = computed(() => {
  const icons = {
    urgent: 'i-lucide-alert-circle',
    high: 'i-lucide-arrow-up',
    medium: 'i-lucide-minus',
    low: 'i-lucide-arrow-down',
  };
  return icons[props.conversation.priority] || null;
});

const openConversation = () => {
  const route = accountScopedRoute('inbox_conversation', {
    conversation_id: props.conversation.id,
  });
  router.push(route);
};
</script>

<template>
  <div
    class="group cursor-grab active:cursor-grabbing rounded-lg border border-n-weak bg-n-surface-1 p-3 shadow-sm hover:shadow-md transition-shadow duration-200"
    @dblclick="openConversation"
  >
    <div class="flex items-start justify-between gap-2">
      <div class="flex items-center gap-2 min-w-0">
        <div
          v-if="conversation.contact?.thumbnail"
          class="size-8 shrink-0 rounded-full bg-cover bg-center"
          :style="{
            backgroundImage: `url(${conversation.contact.thumbnail})`,
          }"
        />
        <div
          v-else
          class="size-8 shrink-0 rounded-full bg-n-brand flex items-center justify-center text-white text-xs font-medium"
        >
          {{ contactInitial }}
        </div>
        <div class="min-w-0">
          <p class="text-sm font-medium text-n-slate-12 truncate">
            {{ contactName }}
          </p>
          <p class="text-xs text-n-slate-11 truncate">
            #{{ conversation.id }}
            <span v-if="conversation.inbox">
              · {{ conversation.inbox.name }}
            </span>
          </p>
        </div>
      </div>
      <div class="flex items-center gap-1.5 shrink-0">
        <span
          v-if="priorityIcon"
          :class="[priorityIcon, 'size-3.5 text-n-slate-11']"
        />
        <span :class="[statusColor, 'size-2 rounded-full']" />
      </div>
    </div>

    <div
      v-if="conversation.labels && conversation.labels.length"
      class="mt-2 flex flex-wrap gap-1"
    >
      <span
        v-for="label in conversation.labels.slice(0, 3)"
        :key="label"
        class="inline-flex items-center rounded px-1.5 py-0.5 text-xs bg-n-alpha-2 text-n-slate-11"
      >
        {{ label }}
      </span>
      <span
        v-if="conversation.labels.length > 3"
        class="text-xs text-n-slate-10"
      >
        +{{ conversation.labels.length - 3 }}
      </span>
    </div>

    <div
      v-if="assigneeName"
      class="mt-2 flex items-center gap-1.5"
    >
      <span class="i-lucide-user size-3 text-n-slate-10" />
      <span class="text-xs text-n-slate-11 truncate">{{ assigneeName }}</span>
    </div>
  </div>
</template>
